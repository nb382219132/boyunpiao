-- Supabase 字段修复脚本
-- 添加缺失的字段到现有表中

-- 修复 stores 表
DO $$
BEGIN
    -- 添加 companyName 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'companyName') THEN
        ALTER TABLE stores ADD COLUMN "companyName" TEXT DEFAULT '';
        RAISE NOTICE 'Added column companyName to stores';
    END IF;

    -- 添加 storeName 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'storeName') THEN
        ALTER TABLE stores ADD COLUMN "storeName" TEXT DEFAULT '';
        RAISE NOTICE 'Added column storeName to stores';
    END IF;

    -- 添加 quarterIncome 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'quarterIncome') THEN
        ALTER TABLE stores ADD COLUMN "quarterIncome" NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column quarterIncome to stores';
    END IF;

    -- 添加 quarterExpenses 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'quarterExpenses') THEN
        ALTER TABLE stores ADD COLUMN "quarterExpenses" NUMERIC DEFAULT 0;
        RAISE NOTICE 'Added column quarterExpenses to stores';
    END IF;

    -- 添加 taxType 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'taxType') THEN
        ALTER TABLE stores ADD COLUMN "taxType" TEXT DEFAULT 'general';
        RAISE NOTICE 'Added column taxType to stores';
    END IF;

    -- 添加 platform 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'stores' AND column_name = 'platform') THEN
        ALTER TABLE stores ADD COLUMN "platform" TEXT DEFAULT '天猫';
        RAISE NOTICE 'Added column platform to stores';
    END IF;
END $$;

-- 修复 suppliers 表
DO $$
BEGIN
    -- 添加 name 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'name') THEN
        ALTER TABLE suppliers ADD COLUMN "name" TEXT DEFAULT '';
        RAISE NOTICE 'Added column name to suppliers';
    END IF;

    -- 添加 owner 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'owner') THEN
        ALTER TABLE suppliers ADD COLUMN "owner" TEXT DEFAULT '';
        RAISE NOTICE 'Added column owner to suppliers';
    END IF;

    -- 添加 type 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'type') THEN
        ALTER TABLE suppliers ADD COLUMN "type" TEXT DEFAULT 'individual';
        RAISE NOTICE 'Added column type to suppliers';
    END IF;

    -- 添加 quarterlyLimit 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'quarterlyLimit') THEN
        ALTER TABLE suppliers ADD COLUMN "quarterlyLimit" NUMERIC DEFAULT 280000;
        RAISE NOTICE 'Added column quarterlyLimit to suppliers';
    END IF;

    -- 添加 status 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'suppliers' AND column_name = 'status') THEN
        ALTER TABLE suppliers ADD COLUMN "status" TEXT DEFAULT 'Active';
        RAISE NOTICE 'Added column status to suppliers';
    END IF;
END $$;

-- 刷新 Supabase 缓存
NOTIFY pgrst, 'reload schema';
