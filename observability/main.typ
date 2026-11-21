== Observability

*Goal:* the architecture decides at design time what every component emits, through what pipeline, with what retention, integrity, and access control. Operations, defense, and compliance are consumers of that output, they do not get to rebuild it after the fact.

=== Observability as an architectural discipline
- The three pillars: logs, metrics, traces, what each answers and where it fails
- Emit-by-design: every component names what it exposes before it is deployed
- Retention, integrity, access control, and cost as design parameters
- Observability and SIEM are the same pipeline with different retention and access policies, not two stacks
- Why separate ops and security observability pipelines is organizational failure dressed as architecture

=== Collection and pipeline
- OpenTelemetry as the unifying collection layer (SDK, Collector)
- Log shippers: Fluent Bit, Vector, Logstash, trade-offs and placement
- Metrics: Prometheus, VictoriaMetrics, pull vs push, cardinality as a design constraint
- Traces: Jaeger, Tempo, sampling strategies
- Schema normalization (ECS, OpenTelemetry semantic conventions)

=== Storage and access
- Hot, warm, and cold tiering
- Retention as compliance and investigation input
- Log integrity: append-only stores, signed shipping, tamper-evidence
- Access control on observability data, itself a security boundary

=== Dashboards and alerting
- Grafana as the shared consumption surface
- Alertmanager and alert design: signal vs noise, routing, silence
- SLOs and error budgets as operational consumption
- Alert fatigue as an architectural failure, not an ops problem

*Architectural question a graduate answers:* *what does this system emit, through what pipeline, with what retention and integrity, and who reads it for what purpose?*

#pagebreak()
