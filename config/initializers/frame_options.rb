# Remove X-Frame-Options header globally for all responses
Rails.application.config.action_dispatch.default_headers.delete('X-Frame-Options')
# Restrict allowed domains for embedding:
Rails.application.config.action_dispatch.default_headers['Content-Security-Policy'] = "frame-ancestors 'self' https://suporte.livoltek.com.br"
