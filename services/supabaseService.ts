import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { StoreCompany, SupplierEntity, InvoiceRecord, PaymentRecord } from '../types';

// 创建Supabase客户端
let supabase: SupabaseClient | null = null;
let lastConnectionAttempt: number = 0;
const RECONNECT_INTERVAL = 60000; // 60秒后重试连接
let hasSupabaseConfig = false;
const MAX_RETRIES = 3; // 最大重试次数
const RETRY_DELAY = 1000; // 重试延迟（毫秒）

// 通用重试函数
const withRetry = async <T>(fn: () => Promise<T>, retries: number = MAX_RETRIES): Promise<T> => {
  try {
    return await fn();
  } catch (error) {
    if (retries > 0) {
      console.warn(`Operation failed, retrying in ${RETRY_DELAY}ms... (${retries} retries left)`, error);
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
      return withRetry(fn, retries - 1);
    }
    throw error;
  }
};

const getSupabaseClient = (): SupabaseClient => {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    hasSupabaseConfig = false;
    throw new Error('Supabase URL or Anon Key is missing from environment variables');
  }
  
  hasSupabaseConfig = true;
  
  // 如果客户端不存在，或者超过了重连间隔，重新创建客户端
  const now = Date.now();
  if (!supabase || (now - lastConnectionAttempt > RECONNECT_INTERVAL)) {
    lastConnectionAttempt = now;
    console.log('Creating or recreating Supabase client with URL:', supabaseUrl);
    
    try {
      // 创建Supabase客户端，并配置连接池和超时
      supabase = createClient(supabaseUrl, supabaseKey, {
        db: {
          pool: 5, // 连接池大小
          timeout: 10000, // 连接超时时间（毫秒）
        },
        auth: {
          persistSession: true,
          autoRefreshToken: true,
        },
      });
      
      // 检查连接状态
      supabase.auth.getSession().then(session => {
        console.log('Supabase connection status:', session.error ? 'error' : 'connected');
        if (session.error) {
          console.error('Supabase connection error:', session.error);
          // 不要保存连接错误，允许下次重试
        } else {
          console.log('Successfully connected to Supabase!');
        }
      });
    } catch (error) {
      console.error('Failed to create Supabase client:', error);
      // 允许下次重试
      throw error;
    }
  }
  
  if (!supabase) {
    throw new Error('Failed to create Supabase client');
  }
  
  return supabase;
};

// 检查是否有Supabase配置
export const isSupabaseConfigured = (): boolean => {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  return !!supabaseUrl && !!supabaseKey;
};

// 用户认证相关功能
export const signUp = async (username: string, password: string): Promise<{ user: any; error: any }> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping sign up');
    return { user: null, error: new Error('Supabase not configured') };
  }
  
  try {
    const client = getSupabaseClient();
    // 将用户名转换为邮箱格式以兼容Supabase认证
    const email = `${username}@example.com`;
    const { data, error } = await client.auth.signUp({
      email,
      password,
      options: {
        data: {
          username: username, // 保存原始用户名
          status: 'pending', // 设置用户状态为待审核
          role: 'user', // 默认角色为普通用户
          level: 'normal', // 默认等级为普通用户
          platforms: [] // 默认无平台关联
        }
      }
    });
    
    return { user: data?.user, error };
  } catch (error) {
    console.error('Failed to sign up:', error);
    return { user: null, error };
  }
};

export const signIn = async (username: string, password: string): Promise<{ user: any; error: any }> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping sign in');
    return { user: null, error: new Error('Supabase not configured') };
  }
  
  try {
    const client = getSupabaseClient();
    // 将用户名转换为邮箱格式以兼容Supabase认证
    const email = `${username}@example.com`;
    const { data, error } = await client.auth.signInWithPassword({
      email,
      password
    });
    
    // 检查用户状态
    if (data?.user?.user_metadata?.status === 'pending') {
      // 登出用户，因为状态未审核
      await client.auth.signOut();
      return { user: null, error: new Error('您的账户正在等待管理员审核，请稍后再试') };
    }
    
    return { user: data?.user, error };
  } catch (error) {
    console.error('Failed to sign in:', error);
    return { user: null, error };
  }
};

export const signOut = async (): Promise<{ error: any }> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping sign out');
    return { error: new Error('Supabase not configured') };
  }
  
  try {
    const client = getSupabaseClient();
    const { error } = await client.auth.signOut();
    
    return { error };
  } catch (error) {
    console.error('Failed to sign out:', error);
    return { error };
  }
};

export const getCurrentUser = (): any => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning null user');
    return null;
  }
  
  try {
    const client = getSupabaseClient();
    return client.auth.getUser();
  } catch (error) {
    console.error('Failed to get current user:', error);
    return null;
  }
};

export const subscribeToAuthChanges = (callback: (user: any) => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, calling callback with null user');
    setTimeout(() => callback(null), 0);
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    client.auth.getSession().then(({ data: { session } }) => {
      callback(session?.user || null);
    }).catch((error) => {
      console.error('Failed to get session:', error);
      callback(null);
    });
    
    const { data: { subscription } } = client.auth.onAuthStateChange((event, session) => {
      callback(session?.user || null);
    });
    
    return subscription;
  } catch (error) {
    console.error('Failed to subscribe to auth changes:', error);
    setTimeout(() => callback(null), 0);
    return { unsubscribe: () => {} };
  }
};

// 实时订阅功能

// 订阅stores表的变化
export const subscribeToStores = (callback: (stores: StoreCompany[]) => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping subscription');
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    console.log('Subscribing to stores changes...');
    
    // 订阅变化，不获取初始数据（由loadData函数负责）
    const channel = client
      .channel('stores-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'stores' }, async (event) => {
        console.log('Stores change event received:', event.eventType);
        const stores = await fetchStores();
        console.log('Updated stores data:', stores.length, 'records');
        callback(stores);
      })
      .subscribe((status) => {
        console.log('Stores channel subscription status:', status);
      });
    
    return channel;
  } catch (error) {
    console.error('Failed to subscribe to stores:', error);
    return { unsubscribe: () => {} };
  }
};

// 订阅suppliers表的变化
export const subscribeToSuppliers = (callback: (suppliers: SupplierEntity[]) => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping subscription');
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    console.log('Subscribing to suppliers changes...');
    
    // 订阅变化，不获取初始数据（由loadData函数负责）
    const channel = client
      .channel('suppliers-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'suppliers' }, async (event) => {
        console.log('Suppliers change event received:', event.eventType);
        const suppliers = await fetchSuppliers();
        console.log('Updated suppliers data:', suppliers.length, 'records');
        callback(suppliers);
      })
      .subscribe((status) => {
        console.log('Suppliers channel subscription status:', status);
      });
    
    return channel;
  } catch (error) {
    console.error('Failed to subscribe to suppliers:', error);
    return { unsubscribe: () => {} };
  }
};

// 订阅factory_owners表的变化
export const subscribeToFactoryOwners = (callback: (factoryOwners: string[]) => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping subscription');
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    console.log('Subscribing to factory_owners changes...');
    
    // 订阅变化，不获取初始数据（由loadData函数负责）
    const channel = client
      .channel('factory-owners-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'factory_owners' }, async (event) => {
        console.log('FactoryOwners change event received:', event.eventType);
        const factoryOwners = await fetchFactoryOwners();
        console.log('Updated factoryOwners data:', factoryOwners.length, 'records');
        callback(factoryOwners);
      })
      .subscribe((status) => {
        console.log('FactoryOwners channel subscription status:', status);
      });
    
    return channel;
  } catch (error) {
    console.error('Failed to subscribe to factory owners:', error);
    return { unsubscribe: () => {} };
  }
};

// 订阅invoices表的变化
export const subscribeToInvoices = (callback: (invoices: InvoiceRecord[]) => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping subscription');
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    console.log('Subscribing to invoices changes...');
    
    // 订阅变化，不获取初始数据（由loadData函数负责）
    const channel = client
      .channel('invoices-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'invoices' }, async (event) => {
        console.log('Invoices change event received:', event.eventType);
        const invoices = await fetchInvoices();
        console.log('Updated invoices data:', invoices.length, 'records');
        callback(invoices);
      })
      .subscribe((status) => {
        console.log('Invoices channel subscription status:', status);
      });
    
    return channel;
  } catch (error) {
    console.error('Failed to subscribe to invoices:', error);
    return { unsubscribe: () => {} };
  }
};

// 订阅payments表的变化
export const subscribeToPayments = (callback: (payments: PaymentRecord[]) => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping subscription');
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    console.log('Subscribing to payments changes...');
    
    // 订阅变化，不获取初始数据（由loadData函数负责）
    const channel = client
      .channel('payments-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'payments' }, async (event) => {
        console.log('Payments change event received:', event.eventType);
        const payments = await fetchPayments();
        console.log('Updated payments data:', payments.length, 'records');
        callback(payments);
      })
      .subscribe((status) => {
        console.log('Payments channel subscription status:', status);
      });
    
    return channel;
  } catch (error) {
    console.error('Failed to subscribe to payments:', error);
    return { unsubscribe: () => {} };
  }
};

// 订阅季度相关数据的变化
export const subscribeToQuarterData = (callback: () => void) => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping subscription');
    return { unsubscribe: () => {} };
  }
  
  try {
    const client = getSupabaseClient();
    
    console.log('Subscribing to quarter data changes...');
    
    // 订阅所有季度相关表的变化，不获取初始数据（由loadData函数负责）
    const channel = client
      .channel('quarter-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'quarter_data' }, (event) => {
        console.log('QuarterData change event received:', event.eventType);
        callback();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'available_quarters' }, (event) => {
        console.log('AvailableQuarters change event received:', event.eventType);
        callback();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'current_quarter' }, (event) => {
        console.log('CurrentQuarter change event received:', event.eventType);
        callback();
      })
      .subscribe((status) => {
        console.log('Quarter channel subscription status:', status);
      });
    
    return channel;
  } catch (error) {
    console.error('Failed to subscribe to quarter data:', error);
    return { unsubscribe: () => {} };
  }
};

// SKU数据相关操作
export const fetchStores = async (): Promise<StoreCompany[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty stores');
    return [];
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      const { data, error } = await client
        .from('stores')
        .select('*');
      
      if (error) {
        console.error('Error fetching stores:', error);
        throw error;
      }
      
      return data as StoreCompany[];
    });
  } catch (error) {
    console.error('Failed to fetch stores:', error);
    return [];
  }
};

export const saveStores = async (stores: StoreCompany[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save stores');
    return false;
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      console.log('Saving stores to Supabase:', stores.length, 'records');
      
      if (stores.length > 0) {
        // 对每个店铺进行upsert，使用乐观锁机制
        for (const store of stores) {
          // 增加版本号
          const updatedStore = {
            ...store,
            version: (store.version || 0) + 1
          };
          
          // 使用upsert方式保存数据，根据id字段更新或插入
          const { error: upsertError } = await client
            .from('stores')
            .upsert(updatedStore, { onConflict: 'id' })
            .select();
          
          if (upsertError) {
            console.error('Error upserting store:', upsertError);
            // 可以在这里处理冲突，例如提示用户或重试
            throw upsertError;
          }
        }
        
        console.log('Successfully upserted stores:', stores.length, 'records');
      }
      
      return true;
    });
  } catch (error) {
    console.error('Failed to save stores:', error);
    return false;
  }
};

// 供应商数据相关操作
export const fetchSuppliers = async (): Promise<SupplierEntity[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty suppliers');
    return [];
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      const { data, error } = await client
        .from('suppliers')
        .select('*');
      
      if (error) {
        console.error('Error fetching suppliers:', error);
        throw error;
      }
      
      return data as SupplierEntity[];
    });
  } catch (error) {
    console.error('Failed to fetch suppliers:', error);
    return [];
  }
};

export const saveSuppliers = async (suppliers: SupplierEntity[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save suppliers');
    return false;
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      console.log('Saving suppliers to Supabase:', suppliers.length, 'records');
      
      if (suppliers.length > 0) {
        // 对每个供应商进行upsert，使用乐观锁机制
        for (const supplier of suppliers) {
          // 增加版本号
          const updatedSupplier = {
            ...supplier,
            version: (supplier.version || 0) + 1
          };
          
          // 使用upsert方式保存数据，根据id字段更新或插入
          const { error: upsertError } = await client
            .from('suppliers')
            .upsert(updatedSupplier, { onConflict: 'id' })
            .select();
          
          if (upsertError) {
            console.error('Error upserting supplier:', upsertError);
            // 可以在这里处理冲突，例如提示用户或重试
            throw upsertError;
          }
        }
        
        console.log('Successfully upserted suppliers:', suppliers.length, 'records');
      }
      
      return true;
    });
  } catch (error) {
    console.error('Failed to save suppliers:', error);
    return false;
  }
};

// 发票数据相关操作
export const fetchInvoices = async (): Promise<InvoiceRecord[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty invoices');
    return [];
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      const { data, error } = await client
        .from('invoices')
        .select('*');
      
      if (error) {
        console.error('Error fetching invoices:', error);
        throw error;
      }
      
      return data as InvoiceRecord[];
    });
  } catch (error) {
    console.error('Failed to fetch invoices:', error);
    return [];
  }
};

export const saveInvoices = async (invoices: InvoiceRecord[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save invoices');
    return false;
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      console.log('Saving invoices to Supabase:', invoices.length, 'records');
      
      if (invoices.length > 0) {
        // 对每个发票进行upsert，使用乐观锁机制
        for (const invoice of invoices) {
          // 增加版本号
          const updatedInvoice = {
            ...invoice,
            version: (invoice.version || 0) + 1
          };
          
          // 使用upsert方式保存数据，根据id字段更新或插入
          const { error: upsertError } = await client
            .from('invoices')
            .upsert(updatedInvoice, { onConflict: 'id' })
            .select();
          
          if (upsertError) {
            console.error('Error upserting invoice:', upsertError);
            // 可以在这里处理冲突，例如提示用户或重试
            throw upsertError;
          }
        }
        
        console.log('Successfully upserted invoices:', invoices.length, 'records');
      }
      
      return true;
    });
  } catch (error) {
    console.error('Failed to save invoices:', error);
    return false;
  }
};

// 付款数据相关操作
export const fetchPayments = async (): Promise<PaymentRecord[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty payments');
    return [];
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      const { data, error } = await client
        .from('payments')
        .select('*');
      
      if (error) {
        console.error('Error fetching payments:', error);
        throw error;
      }
      
      return data as PaymentRecord[];
    });
  } catch (error) {
    console.error('Failed to fetch payments:', error);
    return [];
  }
};

export const savePayments = async (payments: PaymentRecord[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save payments');
    return false;
  }
  
  try {
    return await withRetry(async () => {
      const client = getSupabaseClient();
      console.log('Saving payments to Supabase:', payments.length, 'records');
      
      if (payments.length > 0) {
        // 对每个付款进行upsert，使用乐观锁机制
        for (const payment of payments) {
          // 增加版本号
          const updatedPayment = {
            ...payment,
            version: (payment.version || 0) + 1
          };
          
          // 使用upsert方式保存数据，根据id字段更新或插入
          const { error: upsertError } = await client
            .from('payments')
            .upsert(updatedPayment, { onConflict: 'id' })
            .select();
          
          if (upsertError) {
            console.error('Error upserting payment:', upsertError);
            // 可以在这里处理冲突，例如提示用户或重试
            throw upsertError;
          }
        }
        
        console.log('Successfully upserted payments:', payments.length, 'records');
      }
      
      return true;
    });
  } catch (error) {
    console.error('Failed to save payments:', error);
    return false;
  }
};

// 季度数据相关操作
export const fetchQuarterData = async (): Promise<Record<string, any>> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty quarter data');
    return {};
  }
  
  try {
    const client = getSupabaseClient();
    const { data, error } = await client
      .from('quarter_data')
      .select('*');
    
    if (error) {
      console.error('Error fetching quarter data:', error);
      return {};
    }
    
    // 将数组转换为对象格式
    const quarterData: Record<string, any> = {};
    data.forEach(item => {
      if (item.quarter_name) {
        quarterData[item.quarter_name] = {
          stores: item.stores || [],
          suppliers: item.suppliers || [],
          invoices: item.invoices || [],
          payments: item.payments || []
        };
      }
    });
    
    return quarterData;
  } catch (error) {
    console.error('Failed to fetch quarter data:', error);
    return {};
  }
};

export const saveQuarterData = async (quarterData: Record<string, any>): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save quarter data');
    return false;
  }
  
  try {
    const client = getSupabaseClient();
    
    // 准备upsert数据
    const upsertData = Object.entries(quarterData).map(([quarterName, data]) => ({
      quarter_name: quarterName,
      stores: data.stores || [],
      suppliers: data.suppliers || [],
      invoices: data.invoices || [],
      payments: data.payments || []
    }));
    
    // 使用upsert方式保存数据，根据quarter_name字段更新或插入
    if (upsertData.length > 0) {
      const { error: upsertError } = await client
        .from('quarter_data')
        .upsert(upsertData, { onConflict: 'quarter_name' })
        .select();
      
      if (upsertError) {
        console.error('Error upserting quarter data:', upsertError);
        return false;
      }
    }
    
    return true;
  } catch (error) {
    console.error('Failed to save quarter data:', error);
    return false;
  }
};

// 可用季度列表相关操作
export const fetchAvailableQuarters = async (): Promise<string[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning default quarters');
    return ['2025Q3'];
  }
  
  try {
    const client = getSupabaseClient();
    const { data, error } = await client
      .from('available_quarters')
      .select('quarter_name')
      .order('quarter_name', { ascending: true });
    
    if (error) {
      console.error('Error fetching available quarters:', error);
      return [];
    }
    
    return data.map(item => item.quarter_name);
  } catch (error) {
    console.error('Failed to fetch available quarters:', error);
    return ['2025Q3'];
  }
};

export const saveAvailableQuarters = async (quarters: string[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save available quarters');
    return false;
  }
  
  try {
    const client = getSupabaseClient();
    
    // 对于available_quarters表，我们直接删除所有现有记录，然后插入新记录
    // 这样可以避免id字段类型不匹配的问题
    
    // 先删除所有现有记录
    const { error: deleteError } = await client
      .from('available_quarters')
      .delete()
      .neq('id', '');
    
    if (deleteError) {
      console.error('Error deleting available quarters:', deleteError);
      return false;
    }
    
    // 准备插入数据
    const insertData = quarters.map(quarter => ({
      quarter_name: quarter
    }));
    
    // 插入新数据
    if (insertData.length > 0) {
      const { error: insertError } = await client
        .from('available_quarters')
        .insert(insertData);
      
      if (insertError) {
        console.error('Error inserting available quarters:', insertError);
        return false;
      }
    }
    
    return true;
  } catch (error) {
    console.error('Failed to save available quarters:', error);
    return false;
  }
};

// 当前季度相关操作
export const fetchCurrentQuarter = async (): Promise<string> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning default quarter');
    return '2025Q3';
  }
  
  try {
    const client = getSupabaseClient();
    const { data, error } = await client
      .from('current_quarter')
      .select('quarter_name')
      .limit(1);
    
    if (error) {
      console.error('Error fetching current quarter:', error);
      return '2025Q3'; // 默认值
    }
    
    return data.length > 0 ? data[0].quarter_name : '2025Q3';
  } catch (error) {
    console.error('Failed to fetch current quarter:', error);
    return '2025Q3';
  }
};

export const saveCurrentQuarter = async (quarter: string): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save current quarter');
    return false;
  }
  
  try {
    const client = getSupabaseClient();
    
    // 对于current_quarter表，我们只需要一条记录
    // 先删除所有现有记录
    const { error: deleteError } = await client
      .from('current_quarter')
      .delete()
      .neq('id', '');
    
    if (deleteError) {
      console.error('Error deleting current quarter:', deleteError);
      return false;
    }
    
    // 插入新记录
    const { error: insertError } = await client
      .from('current_quarter')
      .insert({ quarter_name: quarter });
    
    if (insertError) {
      console.error('Error inserting current quarter:', insertError);
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Failed to save current quarter:', error);
    return false;
  }
};

// 工厂所有者相关操作
export const fetchFactoryOwners = async (): Promise<string[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty factory owners');
    return [];
  }
  
  try {
    const client = getSupabaseClient();
    const { data, error } = await client
      .from('factory_owners')
      .select('owner_name')
      .order('owner_name', { ascending: true });
    
    if (error) {
      console.error('Error fetching factory owners:', error);
      return [];
    }
    
    return data.map(item => item.owner_name);
  } catch (error) {
    console.error('Failed to fetch factory owners:', error);
    return [];
  }
};

export const saveFactoryOwners = async (owners: string[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping save factory owners');
    return false;
  }
  
  try {
    const client = getSupabaseClient();
    
    // 先获取现有工厂所有者列表
    const existingOwners = await fetchFactoryOwners();
    
    // 确定需要删除的工厂所有者
    const ownersToDelete = existingOwners.filter(o => !owners.includes(o));
    
    // 删除不存在的工厂所有者
    if (ownersToDelete.length > 0) {
      const { error: deleteError } = await client
        .from('factory_owners')
        .delete()
        .in('owner_name', ownersToDelete);
      
      if (deleteError) {
        console.error('Error deleting factory owners:', deleteError);
        return false;
      }
    }
    
    // 准备插入或更新的数据
    const upsertData = owners.map(owner => ({
      owner_name: owner
    }));
    
    // 使用upsert方式保存数据，根据owner_name字段更新或插入
    if (upsertData.length > 0) {
      const { error: upsertError } = await client
        .from('factory_owners')
        .upsert(upsertData, { onConflict: 'owner_name' })
        .select();
      
      if (upsertError) {
        console.error('Error upserting factory owners:', upsertError);
        return false;
      }
    }
    
    return true;
  } catch (error) {
    console.error('Failed to save factory owners:', error);
    return false;
  }
};

// 从localStorage迁移数据到Supabase
export const migrateDataFromLocalStorage = async (force: boolean = false): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping data migration');
    return false;
  }
  
  try {
    console.log('开始从localStorage迁移数据到Supabase...');
    
    // 从localStorage获取数据
    const storesJson = localStorage.getItem('stores');
    const suppliersJson = localStorage.getItem('suppliers');
    const invoicesJson = localStorage.getItem('invoices');
    const paymentsJson = localStorage.getItem('payments');
    
    // 只有当localStorage中有实际数据时，才执行迁移
    // 避免空数据覆盖Supabase中的现有数据
    if (!storesJson && !suppliersJson && !invoicesJson && !paymentsJson) {
      console.log('localStorage中没有数据，跳过迁移');
      return false; // 返回false，表示需要使用默认数据
    }
    
    // 如果不是强制迁移，检查Supabase中是否已有数据
    // 如果已有数据，就跳过迁移，避免覆盖
    if (!force) {
      const hasData = await hasDataInSupabase();
      if (hasData) {
        console.log('Supabase中已有数据，跳过从localStorage迁移数据');
        return true; // 返回true，表示迁移已完成（跳过）
      }
    }
    
    // 解析数据
    const stores = storesJson ? JSON.parse(storesJson) : [];
    const suppliers = suppliersJson ? JSON.parse(suppliersJson) : [];
    const invoices = invoicesJson ? JSON.parse(invoicesJson) : [];
    const payments = paymentsJson ? JSON.parse(paymentsJson) : [];
    const quarterDataJson = localStorage.getItem('quarterData');
    const availableQuartersJson = localStorage.getItem('availableQuarters');
    const currentQuarter = localStorage.getItem('currentQuarter');
    const factoryOwnersJson = localStorage.getItem('factoryOwners');
    
    const quarterData = quarterDataJson ? JSON.parse(quarterDataJson) : {};
    const availableQuarters = availableQuartersJson ? JSON.parse(availableQuartersJson) : ['2025Q3']; // 默认季度
    const factoryOwners = factoryOwnersJson ? JSON.parse(factoryOwnersJson) : [...new Set(suppliers.map(s => s.owner))]; // 从供应商中提取所有者
    
    console.log('迁移数据量:', {
      stores: stores.length,
      suppliers: suppliers.length,
      invoices: invoices.length,
      payments: payments.length,
      availableQuarters: availableQuarters.length,
      factoryOwners: factoryOwners.length
    });
    
    // 保存数据到Supabase，设置超时时间
    const client = getSupabaseClient();
    
    // 保存核心数据
    await Promise.all([
      saveStores(stores),
      saveSuppliers(suppliers),
      saveInvoices(invoices),
      savePayments(payments),
      saveFactoryOwners(factoryOwners)
    ]);
    
    // 保存季度数据
    await Promise.all([
      saveAvailableQuarters(availableQuarters),
      saveCurrentQuarter(currentQuarter || '2025Q3')
    ]);
    
    // 保存季度数据（如果有）
    if (Object.keys(quarterData).length > 0) {
      await saveQuarterData(quarterData);
    }
    
    console.log('数据迁移成功！');
    return true;
  } catch (error) {
    console.error('数据迁移失败:', error);
    return false;
  }
};

// 从备份恢复数据到Supabase（不管Supabase中是否已有数据）
export const restoreDataFromBackup = async (): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping data restore');
    return false;
  }
  
  try {
    console.log('开始从备份恢复数据到Supabase...');
    
    // 首先尝试从localStorage迁移数据
    const migrateResult = await migrateDataFromLocalStorage(true);
    
    if (migrateResult) {
      console.log('从localStorage迁移数据成功！');
      return true;
    } else {
      console.log('localStorage中没有数据，使用默认数据恢复...');
      
      // 如果localStorage中没有数据，使用默认数据恢复
      // 这里我们直接返回true，因为loadData函数会在需要时自动保存默认数据
      return true;
    }
  } catch (error) {
    console.error('数据恢复失败:', error);
    return false;
  }
};

// 检查Supabase是否已有数据
export const hasDataInSupabase = async (): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning false for hasDataInSupabase');
    return false;
  }
  
  try {
    const client = getSupabaseClient();
    
    // 检查多个表，只要有一个表有数据就返回true
    // 避免因为单个表为空导致数据被重置
    const [storesResult, suppliersResult, invoicesResult] = await Promise.all([
      client.from('stores').select('id').limit(1).timeout(3000),
      client.from('suppliers').select('id').limit(1).timeout(3000),
      client.from('invoices').select('id').limit(1).timeout(3000)
    ]);
    
    // 检查是否有任何错误
    const hasError = storesResult.error || suppliersResult.error || invoicesResult.error;
    if (hasError) {
      console.error('Error checking data existence:', hasError);
      return false;
    }
    
    // 只要有一个表有数据就返回true
    const hasData = storesResult.data.length > 0 || suppliersResult.data.length > 0 || invoicesResult.data.length > 0;
    console.log('hasDataInSupabase result:', hasData);
    return hasData;
  } catch (error) {
    console.error('Error checking data existence:', error);
    return false;
  }
};

// 创建管理员账号
export const createAdminAccount = async (): Promise<{ user: any; error: any }> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping create admin account');
    return { user: null, error: new Error('Supabase not configured') };
  }
  
  try {
    const client = getSupabaseClient();
    const username = 'boyunfapiao';
    const password = '9fJ3GzEIjNPkqsNz';
    const email = `${username}@example.com`;
    
    // 使用管理员API检查用户是否存在，而不是登录
    const { data: users, error: usersError } = await client
      .from('users')
      .select('*')
      .eq('username', username)
      .limit(1);
    
    // 如果用户已存在，直接返回
    if (users && users.length > 0) {
      console.log('Admin account already exists');
      return { user: users[0], error: null };
    }
    
    // 如果用户不存在，尝试创建管理员账号
    console.log('Creating admin account...');
    const { data, error } = await client.auth.signUp({
      email,
      password,
      options: {
        data: {
          username: username,
          status: 'active',
          role: 'admin',
          level: 'advanced',
          platforms: []
        }
      }
    });
    
    if (error) {
      console.error('Error creating admin account:', error);
      return { user: null, error };
    }
    
    console.log('Admin account created successfully');
    return { user: data?.user, error: null };
  } catch (error) {
    console.error('Failed to create admin account:', error);
    return { user: null, error };
  }
};

// 用户管理相关功能
export const getUsers = async (): Promise<any[]> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, returning empty users');
    return [];
  }
  
  try {
    const client = getSupabaseClient();
    
    // 注意：在实际生产环境中，需要添加权限检查，确保只有管理员可以获取用户列表
    // 这里简化处理，假设所有登录用户都是管理员
    const { data, error } = await client
      .from('users')
      .select('*');
    
    if (error) {
      console.error('Error fetching users:', error);
      return [];
    }
    
    return data;
  } catch (error) {
    console.error('Failed to fetch users:', error);
    return [];
  }
};

export const updateUserStatus = async (userId: string, status: 'active' | 'pending' | 'blocked', platforms?: string[], level?: 'normal' | 'advanced'): Promise<boolean> => {
  if (!isSupabaseConfigured()) {
    console.warn('Supabase not configured, skipping update user status');
    return false;
  }
  
  try {
    const client = getSupabaseClient();
    
    // 获取用户当前信息
    const { data: userData, error: getUserError } = await client.auth.admin.getUserById(userId);
    if (getUserError) {
      console.error('Error getting user:', getUserError);
      return false;
    }
    
    // 构建更新数据
    const updateData: any = {
      user_metadata: {
        ...userData.user?.user_metadata,
        status: status
      }
    };
    
    // 如果提供了平台信息，更新平台
    if (platforms !== undefined) {
      updateData.user_metadata.platforms = platforms;
    }
    
    // 如果提供了等级信息，更新等级
    if (level !== undefined) {
      updateData.user_metadata.level = level;
    }
    
    // 更新用户元数据
    const { error } = await client.auth.admin.updateUserById(userId, updateData);
    
    if (error) {
      console.error('Error updating user status:', error);
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Failed to update user status:', error);
    return false;
  }
};
