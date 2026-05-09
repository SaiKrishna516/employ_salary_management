# ──────────────────────────────────────────────────────────────────────────────
# Stage 1: production image
# ──────────────────────────────────────────────────────────────────────────────
FROM ruby:3.2.2-alpine AS production

# System dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    curl \
    git

WORKDIR /app

# Install gems (production only) — layer cached unless Gemfile changes
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy full source
COPY . .

# Precompile bootsnap cache for faster boot
RUN bundle exec bootsnap precompile --gemfile app/ lib/

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV PORT=3001

EXPOSE 3001

COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# ──────────────────────────────────────────────────────────────────────────────
# Stage 2: development image (includes dev/test gems, no bootsnap precompile)
# ──────────────────────────────────────────────────────────────────────────────
FROM ruby:3.2.2-alpine AS development

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    curl \
    git \
    bash

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

ENV RAILS_ENV=development
ENV PORT=3001

EXPOSE 3001
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
