const SUPABASE_URL = process.env.SUPABASE_URL || 'https://dhabrfnfirhhcrdbvzdi.supabase.co';
const JWKS_URI = `${SUPABASE_URL}/auth/v1/.well-known/jwks.json`;

let JWKS = null;

function authMiddleware() {
  return async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.json({ ok: false, error: 'Missing or invalid Authorization header' });
    }

    const token = authHeader.slice(7);
    try {
      const jose = await import('jose');
      if (!JWKS) {
        JWKS = jose.createRemoteJWKSet(new URL(JWKS_URI));
      }
      const { payload } = await jose.jwtVerify(token, JWKS, {
        issuer: `${SUPABASE_URL}/auth/v1`,
      });
      req.user = payload;
      next();
    } catch (e) {
      console.error('[AUTH] Token verification failed:', e.message);
      return res.json({ ok: false, error: 'Invalid or expired token' });
    }
  };
}

module.exports = { authMiddleware };
