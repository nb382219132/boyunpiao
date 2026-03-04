-- Supabase 表结构修复脚本
-- 执行此脚本将检查并添加所有缺失的字段

-- ============================================
-- 1. 修复 stores 表
-- ============================================

-- 检查并添加 stores 表的字段
DO $$
BEGIN
    -- 添加 companyName 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'companyName') THEN
        ALTER TABLE stores ADD COLUMN companyName TEXT;
        RAISE NOTICE 'Added column companyName to stores';
    END IF;

    -- 添加 storeName 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'storeName') THEN
        ALTER TABLE stores ADD COLUMN storeName TEXT;
        RAISE NOTICE 'Added column storeName to stores';
    END IF;

    -- 添加 quarterIncome 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'quarterIncome') THEN
        ALTER TABLE stores ADD COLUMN quarterIncome NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column quarterIncome to stores';
    END IF;

    -- 添加 quarterExpenses 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'quarterExpenses') THEN
        ALTER TABLE stores ADD COLUMN quarterExpenses NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column quarterExpenses to stores';
    END IF;

    -- 添加 taxType 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'taxType') THEN
        ALTER TABLE stores ADD COLUMN taxType TEXT DEFAULT 'general';
        RAISE NOTICE 'Added column taxType to stores';
    END IF;

    -- 添加 platform 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'platform') THEN
        ALTER TABLE stores ADD COLUMN platform TEXT DEFAULT '天猫';
        RAISE NOTICE 'Added column platform to stores';
    END IF;
END $$;

-- ============================================
-- 2. 修复 suppliers 表
-- ============================================

DO $$
BEGIN
    -- 添加 name 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'name') THEN
        ALTER TABLE suppliers ADD COLUMN name TEXT;
        RAISE NOTICE 'Added column name to suppliers';
    END IF;

    -- 添加 owner 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'owner') THEN
        ALTER TABLE suppliers ADD COLUMN owner TEXT;
        RAISE NOTICE 'Added column owner to suppliers';
    END IF;

    -- 添加 type 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'type') THEN
        ALTER TABLE suppliers ADD COLUMN type TEXT DEFAULT 'individual';
        RAISE NOTICE 'Added column type to suppliers';
    END IF;

    -- 添加 quarterlyLimit 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'quarterlyLimit') THEN
        ALTER TABLE suppliers ADD COLUMN quarterlyLimit NUMERIC DEFAULT 280000;
        RAISE NOTICE 'Added column quarterlyLimit to suppliers';
    END IF;

    -- 添加 status 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'status') THEN
        ALTER TABLE suppliers ADD COLUMN status TEXT DEFAULT 'Active';
        RAISE NOTICE 'Added column status to suppliers';
    END IF;
END $$;

-- ============================================
-- 3. 修复 invoices 表
-- ============================================

DO $$
BEGIN
    -- 添加 storeId 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'storeId') THEN
        ALTER TABLE invoices ADD COLUMN storeId TEXT;
        RAISE NOTICE 'Added column storeId to invoices';
    END IF;

    -- 添加 supplierId 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'supplierId') THEN
        ALTER TABLE invoices ADD COLUMN supplierId TEXT;
        RAISE NOTICE 'Added column supplierId to invoices';
    END IF;

    -- 添加 amount 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'amount') THEN
        ALTER TABLE invoices ADD COLUMN amount NUMERIC;
        RAISE NOTICE 'Added column amount to invoices';
    END IF;

    -- 添加 date 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'date') THEN
        ALTER TABLE invoices ADD COLUMN date TEXT;
        RAISE NOTICE 'Added column date to invoices';
    END IF;

    -- 添加 invoiceType 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'invoiceType') THEN
        ALTER TABLE invoices ADD COLUMN invoiceType TEXT DEFAULT '普通发票';
        RAISE NOTICE 'Added column invoiceType to invoices';
    END IF;

    -- 添加 taxRate 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'taxRate') THEN
        ALTER TABLE invoices ADD COLUMN taxRate NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column taxRate to invoices';
    END IF;

    -- 添加 status 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'status') THEN
        ALTER TABLE invoices ADD COLUMN status TEXT DEFAULT 'pending';
        RAISE NOTICE 'Added column status to invoices';
    END IF;
END $$;

-- ============================================
-- 4. 修复 payments 表
-- ============================================

DO $$
BEGIN
    -- 添加 supplierId 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'payments' AND column_name = 'supplierId') THEN
        ALTER TABLE payments ADD COLUMN supplierId TEXT;
        RAISE NOTICE 'Added column supplierId to payments';
    END IF;

    -- 添加 amount 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'payments' AND column_name = 'amount') THEN
        ALTER TABLE payments ADD COLUMN amount NUMERIC;
        RAISE NOTICE 'Added column amount to payments';
    END IF;

    -- 添加 date 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'payments' AND column_name = 'date') THEN
        ALTER TABLE payments ADD COLUMN date TEXT;
        RAISE NOTICE 'Added column date to payments';
    END IF;

    -- 添加 description 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'payments' AND column_name = 'description') THEN
        ALTER TABLE payments ADD COLUMN description TEXT;
        RAISE NOTICE 'Added column description to payments';
    END IF;
END $$;

-- ============================================
-- 5. 启用 RLS 策略（如果未启用）
-- ============================================

-- 为 stores 表启用 RLS
ALTER TABLE IF EXISTS stores ENABLE ROW LEVEL SECURITY;

-- 为 suppliers 表启用 RLS
ALTER TABLE IF EXISTS suppliers ENABLE ROW LEVEL SECURITY;

-- 为 invoices 表启用 RLS
ALTER TABLE IF EXISTS invoices ENABLE ROW LEVEL SECURITY;

-- 为 payments 表启用 RLS
ALTER TABLE IF EXISTS payments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. 创建 RLS 策略（如果不存在）
-- ============================================

-- stores 表策略
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'stores' AND policyname = 'Allow all') THEN
        CREATE POLICY "Allow all" ON stores FOR ALL USING (true) WITH CHECK (true);
        RAISE NOTICE 'Created policy for stores';
    END IF;
END $$;

-- suppliers 表策略
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'suppliers' AND policyname = 'Allow all') THEN
        CREATE POLICY "Allow all" ON suppliers FOR ALL USING (true) WITH CHECK (true);
        RAISE NOTICE 'Created policy for suppliers';
    END IF;
END $$;

-- invoices 表策略
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'invoices' AND policyname = 'Allow all') THEN
        CREATE POLICY "Allow all" ON invoices FOR ALL USING (true) WITH CHECK (true);
        RAISE NOTICE 'Created policy for invoices';
    END IF;
END $$;

-- payments 表策略
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payments' AND policyname = 'Allow all') THEN
        CREATE POLICY "Allow all" ON payments FOR ALL USING (true) WITH CHECK (true);
        RAISE NOTICE 'Created policy for payments';
    END IF;
END $$;

-- ============================================
-- 完成
-- ============================================
SELECT 'Schema fix completed!' as status;
