-- Receipt24: User device/session tracking (Phase 13)

CREATE TABLE public.user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  device_label TEXT,
  platform TEXT NOT NULL DEFAULT 'unknown',
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, platform, device_label)
);

CREATE INDEX idx_user_devices_user ON public.user_devices(user_id);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_devices_select_own" ON public.user_devices
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "user_devices_insert_own" ON public.user_devices
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_devices_update_own" ON public.user_devices
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "user_devices_delete_own" ON public.user_devices
  FOR DELETE USING (user_id = auth.uid());

CREATE TRIGGER set_updated_at_user_devices
  BEFORE UPDATE ON public.user_devices
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
