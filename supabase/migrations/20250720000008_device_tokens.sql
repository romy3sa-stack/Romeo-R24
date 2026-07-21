-- Receipt24: Device tokens for push notifications (Phase 10)

CREATE TABLE public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

CREATE INDEX idx_device_tokens_user ON public.device_tokens(user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_select_own" ON public.device_tokens
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "device_tokens_insert_own" ON public.device_tokens
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_update_own" ON public.device_tokens
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "device_tokens_delete_own" ON public.device_tokens
  FOR DELETE USING (user_id = auth.uid());

CREATE TRIGGER set_updated_at_device_tokens
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
