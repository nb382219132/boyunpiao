-- Supabase 表结构修复脚本
-- 执行此脚本将检查并添加所有缺失的字段
-- 注意：PostgreSQL 列名不区分大小写，统一使用小写检查

-- ============================================
-- 1. 修复 stores 表
-- ============================================

-- 检查并添加 stores 表的字段
DO $$
BEGIN
    -- 添加 companyname 字段 (PostgreSQL 中存储为小写)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'companyname') THEN
        ALTER TABLE stores ADD COLUMN "companyName" TEXT;
        RAISE NOTICE 'Added column companyName to stores';
    END IF;

    -- 添加 storename 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'storename') THEN
        ALTER TABLE stores ADD COLUMN "storeName" TEXT;
        RAISE NOTICE 'Added column storeName to stores';
    END IF;

    -- 添加 quarterincome 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'quarterincome') THEN
        ALTER TABLE stores ADD COLUMN "quarterIncome" NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column quarterIncome to stores';
    END IF;

    -- 添加 quarterexpenses 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'quarterexpenses') THEN
        ALTER TABLE stores ADD COLUMN "quarterExpenses" NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column quarterExpenses to stores';
    END IF;

    -- 添加 taxtype 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'taxtype') THEN
        ALTER TABLE stores ADD COLUMN "taxType" TEXT DEFAULT 'general';
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

    -- 添加 quarterlylimit 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'quarterlylimit') THEN
        ALTER TABLE suppliers ADD COLUMN "quarterlyLimit" NUMERIC DEFAULT 280000;
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
    -- 添加 storeid 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'storeid') THEN
        ALTER TABLE invoices ADD COLUMN "storeId" TEXT;
        RAISE NOTICE 'Added column storeId to invoices';
    END IF;

    -- 添加 supplierid 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'supplierid') THEN
        ALTER TABLE invoices ADD COLUMN "supplierId" TEXT;
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

    -- 添加 invoicetype 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'invoicetype') THEN
        ALTER TABLE invoices ADD COLUMN "invoiceType" TEXT DEFAULT '普通发票';
        RAISE NOTICE 'Added column invoiceType to invoices';
    END IF;

    -- 添加 taxrate 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'invoices' AND column_name = 'taxrate') THEN
        ALTER TABLE invoices ADD COLUMN "taxRate" NUMERIC DEFAULT 0;
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
    -- 添加 supplierid 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'payments' AND column_name = 'supplierid') THEN
        ALTER TABLE payments ADD COLUMN "supplierId" TEXT;
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
