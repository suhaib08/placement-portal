FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

# Used ONLY to demonstrate a failed rollout (Jenkins parameter FAULTY_BUILD=true).
# An invalid nginx config makes the container crash on start -> CrashLoopBackOff,
# the readiness probe never passes, and the pipeline rolls back automatically.
ARG FAULTY=false
RUN if [ "$FAULTY" = "true" ]; then echo "this_is_not_a_valid_directive on;" > /etc/nginx/conf.d/default.conf; fi

EXPOSE 80
