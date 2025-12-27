-- 《地球新主》游戏核心数据表
-- Migration: 001_create_core_tables

-- ============================================
-- 1. profiles（用户资料）
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 启用RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS策略：用户可以查看所有资料
CREATE POLICY "profiles_select_all" ON profiles
    FOR SELECT USING (true);

-- RLS策略：用户只能更新自己的资料
CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- RLS策略：用户只能插入自己的资料
CREATE POLICY "profiles_insert_own" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. territories（领地）
-- ============================================
CREATE TABLE IF NOT EXISTS territories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    path JSONB NOT NULL,  -- 路径点数组 [{lat, lng}, ...]
    area DECIMAL(15, 2) NOT NULL,  -- 面积（平方米）
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_territories_user_id ON territories(user_id);

-- 启用RLS
ALTER TABLE territories ENABLE ROW LEVEL SECURITY;

-- RLS策略：所有人可以查看领地
CREATE POLICY "territories_select_all" ON territories
    FOR SELECT USING (true);

-- RLS策略：用户只能创建自己的领地
CREATE POLICY "territories_insert_own" ON territories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS策略：用户只能更新自己的领地
CREATE POLICY "territories_update_own" ON territories
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS策略：用户只能删除自己的领地
CREATE POLICY "territories_delete_own" ON territories
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. pois（兴趣点）
-- ============================================
CREATE TABLE IF NOT EXISTS pois (
    id TEXT PRIMARY KEY,  -- 外部ID（如高德POI ID）
    poi_type TEXT NOT NULL,  -- hospital/supermarket/factory等
    name TEXT NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    discovered_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    discovered_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_pois_type ON pois(poi_type);
CREATE INDEX idx_pois_discovered_by ON pois(discovered_by);
CREATE INDEX idx_pois_location ON pois(latitude, longitude);

-- 启用RLS
ALTER TABLE pois ENABLE ROW LEVEL SECURITY;

-- RLS策略：所有人可以查看POI
CREATE POLICY "pois_select_all" ON pois
    FOR SELECT USING (true);

-- RLS策略：登录用户可以发现新POI
CREATE POLICY "pois_insert_authenticated" ON pois
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================
-- 触发器：自动创建用户资料
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, username)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'Player_' || LEFT(NEW.id::TEXT, 8))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
