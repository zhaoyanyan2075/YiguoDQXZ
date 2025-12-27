-- 《地球新主》核心数据表
-- 创建时间: 2025-12-27

-- ============================================
-- 1. profiles（用户资料表）
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);

-- 启用 RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户可以查看所有资料
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT USING (true);

-- RLS 策略：用户只能更新自己的资料
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- RLS 策略：用户只能插入自己的资料
CREATE POLICY "profiles_insert_policy" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. territories（领地表）
-- ============================================
CREATE TABLE IF NOT EXISTS public.territories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    path JSONB NOT NULL,  -- 路径点数组 [{lat, lng}, ...]
    area DOUBLE PRECISION NOT NULL,  -- 面积（平方米）
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_territories_user_id ON public.territories(user_id);
CREATE INDEX IF NOT EXISTS idx_territories_created_at ON public.territories(created_at DESC);

-- 启用 RLS
ALTER TABLE public.territories ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看领地
CREATE POLICY "territories_select_policy" ON public.territories
    FOR SELECT USING (true);

-- RLS 策略：用户只能创建自己的领地
CREATE POLICY "territories_insert_policy" ON public.territories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS 策略：用户只能更新自己的领地
CREATE POLICY "territories_update_policy" ON public.territories
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS 策略：用户只能删除自己的领地
CREATE POLICY "territories_delete_policy" ON public.territories
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. pois（兴趣点表）
-- ============================================
CREATE TABLE IF NOT EXISTS public.pois (
    id TEXT PRIMARY KEY,  -- 外部POI ID
    poi_type TEXT NOT NULL,  -- hospital, supermarket, factory, park, bank, school, gas_station
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    discovered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    discovered_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_pois_poi_type ON public.pois(poi_type);
CREATE INDEX IF NOT EXISTS idx_pois_discovered_by ON public.pois(discovered_by);
CREATE INDEX IF NOT EXISTS idx_pois_location ON public.pois(latitude, longitude);

-- 启用 RLS
ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可以查看POI
CREATE POLICY "pois_select_policy" ON public.pois
    FOR SELECT USING (true);

-- RLS 策略：已登录用户可以插入POI
CREATE POLICY "pois_insert_policy" ON public.pois
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- RLS 策略：发现者可以更新POI
CREATE POLICY "pois_update_policy" ON public.pois
    FOR UPDATE USING (auth.uid() = discovered_by);

-- ============================================
-- 4. 创建用户注册触发器（自动创建 profile）
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'explorer_' || LEFT(NEW.id::TEXT, 8)),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 删除旧触发器（如果存在）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 创建触发器
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 添加表注释
-- ============================================
COMMENT ON TABLE public.profiles IS '用户资料表';
COMMENT ON TABLE public.territories IS '领地表';
COMMENT ON TABLE public.pois IS '兴趣点表';

COMMENT ON COLUMN public.territories.path IS '领地边界路径点数组，格式: [{lat: number, lng: number}, ...]';
COMMENT ON COLUMN public.territories.area IS '领地面积，单位：平方米';
COMMENT ON COLUMN public.pois.poi_type IS 'POI类型: hospital, supermarket, factory, park, bank, school, gas_station';
