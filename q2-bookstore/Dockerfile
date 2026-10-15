FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY tests/check.sh /tests/check.sh

# GATE 1: the build fails if the page does not pass the automated checks
RUN sed -i 's/\r$//' /tests/check.sh && sh /tests/check.sh

# Used ONLY to demonstrate a failed rollout (Jenkins parameter FAULTY_BUILD=true).
# The page still passes the content tests, but the invalid nginx config makes the
# container crash at start-up, so the Kubernetes rollout fails and is rolled back.
ARG FAULTY=false
RUN if [ "$FAULTY" = "true" ]; then echo "this_is_not_a_valid_directive on;" > /etc/nginx/conf.d/default.conf; fi

EXPOSE 80
