-- Supabase 完整部署脚本
-- 包含表结构创建和初始数据

-- 1. 店铺表 (stores)
CREATE TABLE IF NOT EXISTS stores (
    id TEXT PRIMARY KEY,
    storeName TEXT NOT NULL,
    companyName TEXT NOT NULL,
    quarterIncome NUMERIC DEFAULT 0,
    quarterExpenses NUMERIC DEFAULT 0,
    taxType TEXT DEFAULT 'general',
    platform TEXT DEFAULT '天猫',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. 供应商/工厂表 (suppliers)
CREATE TABLE IF NOT EXISTS suppliers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner TEXT NOT NULL,
    type TEXT DEFAULT 'individual',
    quarterlyLimit NUMERIC DEFAULT 280000,
    status TEXT DEFAULT 'Active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. 发票记录表 (invoices)
CREATE TABLE IF NOT EXISTS invoices (
    id TEXT PRIMARY KEY,
    storeId TEXT NOT NULL,
    supplierId TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    date TEXT NOT NULL,
    invoiceType TEXT DEFAULT '普通发票',
    taxRate NUMERIC DEFAULT 0,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. 付款记录表 (payments)
CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY,
    supplierId TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    date TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 5. 季度数据表 (quarter_data)
CREATE TABLE IF NOT EXISTS quarter_data (
    quarter_name TEXT PRIMARY KEY,
    stores JSONB DEFAULT '[]'::jsonb,
    suppliers JSONB DEFAULT '[]'::jsonb,
    invoices JSONB DEFAULT '[]'::jsonb,
    payments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. 可用季度表 (available_quarters)
CREATE TABLE IF NOT EXISTS available_quarters (
    quarter_name TEXT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 7. 当前季度表 (current_quarter)
CREATE TABLE IF NOT EXISTS current_quarter (
    id INTEGER PRIMARY KEY DEFAULT 1,
    quarter_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 8. 工厂所有者表 (factory_owners)
CREATE TABLE IF NOT EXISTS factory_owners (
    owner_name TEXT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 9. 用户表 (users)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'user',
    level TEXT DEFAULT 'normal',
    platforms JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
DROP TRIGGER IF EXISTS update_stores_updated_at ON stores;
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_suppliers_updated_at ON suppliers;
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_quarter_data_updated_at ON quarter_data;
CREATE TRIGGER update_quarter_data_updated_at BEFORE UPDATE ON quarter_data
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_current_quarter_updated_at ON current_quarter;
CREATE TRIGGER update_current_quarter_updated_at BEFORE UPDATE ON current_quarter
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 启用行级安全策略 (RLS)
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE quarter_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE available_quarters ENABLE ROW LEVEL SECURITY;
ALTER TABLE current_quarter ENABLE ROW LEVEL SECURITY;
ALTER TABLE factory_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Allow all" ON stores;
DROP POLICY IF EXISTS "Allow all" ON suppliers;
DROP POLICY IF EXISTS "Allow all" ON invoices;
DROP POLICY IF EXISTS "Allow all" ON payments;
DROP POLICY IF EXISTS "Allow all" ON quarter_data;
DROP POLICY IF EXISTS "Allow all" ON available_quarters;
DROP POLICY IF EXISTS "Allow all" ON current_quarter;
DROP POLICY IF EXISTS "Allow all" ON factory_owners;
DROP POLICY IF EXISTS "Allow all" ON users;

-- 创建允许所有操作的策略（开发阶段使用）
CREATE POLICY "Allow all" ON stores FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON suppliers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON invoices FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON payments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON quarter_data FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON available_quarters FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON current_quarter FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON factory_owners FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON users FOR ALL USING (true) WITH CHECK (true);

-- ==================== 初始化数据 ====================

-- 插入默认当前季度
INSERT INTO current_quarter (id, quarter_name) VALUES (1, '2025Q3')
ON CONFLICT (id) DO UPDATE SET quarter_name = EXCLUDED.quarter_name;

-- 插入默认可用季度
INSERT INTO available_quarters (quarter_name) VALUES ('2025Q3')
ON CONFLICT (quarter_name) DO NOTHING;

-- 初始化季度数据（空数据）
INSERT INTO quarter_data (quarter_name, stores, suppliers, invoices, payments) VALUES
('2025Q3', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb)
ON CONFLICT (quarter_name) DO NOTHING;
