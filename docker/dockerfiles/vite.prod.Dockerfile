FROM ghcr.io/gridtechrnd/livdesk-production:latest

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3036
CMD ["bin/vite", "build"]
