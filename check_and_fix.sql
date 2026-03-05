-- 检查并修复 Supabase 表结构
-- 1. 先删除旧表（如果存在）
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS quarter_data CASCADE;
DROP TABLE IF EXISTS available_quarters CASCADE;
DROP TABLE IF EXISTS current_quarter CASCADE;
DROP TABLE IF EXISTS factory_owners CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 2. 重新创建所有表
-- 店铺表 (stores)
CREATE TABLE stores (
    id TEXT PRIMARY KEY,
    "storeName" TEXT NOT NULL DEFAULT '',
    "companyName" TEXT NOT NULL DEFAULT '',
    "quarterIncome" NUMERIC DEFAULT 0,
    "quarterExpenses" NUMERIC DEFAULT 0,
    "taxType" TEXT DEFAULT 'general',
    "platform" TEXT DEFAULT '天猫',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 供应商/工厂表 (suppliers)
CREATE TABLE suppliers (
    id TEXT PRIMARY KEY,
    "name" TEXT NOT NULL DEFAULT '',
    "owner" TEXT NOT NULL DEFAULT '',
    "type" TEXT DEFAULT 'individual',
    "quarterlyLimit" NUMERIC DEFAULT 280000,
    "status" TEXT DEFAULT 'Active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 发票记录表 (invoices)
CREATE TABLE invoices (
    id TEXT PRIMARY KEY,
    "storeId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    date TEXT NOT NULL,
    "invoiceType" TEXT DEFAULT '普通发票',
    "taxRate" NUMERIC DEFAULT 0,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 付款记录表 (payments)
CREATE TABLE payments (
    id TEXT PRIMARY KEY,
    "supplierId" TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    date TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 季度数据表 (quarter_data)
CREATE TABLE quarter_data (
    quarter_name TEXT PRIMARY KEY,
    stores JSONB DEFAULT '[]'::jsonb,
    suppliers JSONB DEFAULT '[]'::jsonb,
    invoices JSONB DEFAULT '[]'::jsonb,
    payments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 可用季度表 (available_quarters)
CREATE TABLE available_quarters (
    quarter_name TEXT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 当前季度表 (current_quarter)
CREATE TABLE current_quarter (
    id INTEGER PRIMARY KEY DEFAULT 1,
    quarter_name TEXT NOT NULL DEFAULT '2025Q3',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 工厂所有者表 (factory_owners)
CREATE TABLE factory_owners (
    owner_name TEXT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 用户表 (users)
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'user',
    level TEXT DEFAULT 'normal',
    platforms JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. 创建触发器
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quarter_data_updated_at BEFORE UPDATE ON quarter_data
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_current_quarter_updated_at BEFORE UPDATE ON current_quarter
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. 启用 RLS
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE quarter_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE available_quarters ENABLE ROW LEVEL SECURITY;
ALTER TABLE current_quarter ENABLE ROW LEVEL SECURITY;
ALTER TABLE factory_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 6. 创建策略
CREATE POLICY "Allow all" ON stores FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON suppliers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON invoices FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON payments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON quarter_data FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON available_quarters FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON current_quarter FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON factory_owners FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON users FOR ALL USING (true) WITH CHECK (true);

-- 7. 插入初始数据
INSERT INTO current_quarter (id, quarter_name) VALUES (1, '2025Q3')
ON CONFLICT (id) DO UPDATE SET quarter_name = EXCLUDED.quarter_name;

INSERT INTO available_quarters (quarter_name) VALUES ('2025Q3'), ('2025Q4')
ON CONFLICT (quarter_name) DO NOTHING;

INSERT INTO quarter_data (quarter_name, stores, suppliers, invoices, payments) VALUES
('2025Q3', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb),
('2025Q4', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb)
ON CONFLICT (quarter_name) DO NOTHING;
