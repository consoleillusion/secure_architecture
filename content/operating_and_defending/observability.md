---
cnl: ste
cnl-version: 1
cnl-scope: narrative
lexicon: core-v1
lint: light
---
# Observability

**Goal:** the architecture decides at design time what every component emits, through what pipeline, with what retention, integrity and access control. Operations, defence and compliance are consumers of that output; they do not get to rebuild it after the fact.

## Observability as an architectural discipline

Logs, metrics and traces answer different questions and fail in different ways. A log says that a specific event occurred; it is precise but expensive to store and hard to query at scale. A metric says how a quantity changed over time; it is cheap and aggregable but loses the individual event. A trace says how a request moved through services; it is excellent for latency and dependency questions and useless without consistent identifiers. An architecture that claims all three from one mechanism has not thought about what it needs to answer.

**Emit by design** means each component names, before deployment, what it exposes, in what schema and at what volume. A component that can only be inspected by attaching a debugger after an incident was not designed to be operated. Retention, integrity, access control and cost are design parameters alongside the event list: an unbounded log stream with no access boundary is a data leak with a retention schedule.

Operations and security observability are the same pipeline with different retention and access policies. Two stacks imply two schemas, two collection paths and two sets of gaps, and the gap between them is exactly where incidents hide. Separating them is an organisational failure dressed as architecture.

## Collection and pipeline

OpenTelemetry provides the SDK and Collector layer that most new components should use. Fluent Bit and Vector are efficient log shippers for host and container environments; Logstash remains where existing ES installations justify it. Placement matters: a shipper that shares a failure domain with the service it observes loses evidence at the moment evidence matters most.

For metrics, Prometheus and VictoriaMetrics use a pull model that makes target health visible but requires network reachability and careful handling of high-cardinality labels. Push-based alternatives invert that trade. Cardinality is a design constraint, not a tuning problem: a label with unbounded values will eventually exhaust the store. Traces use Jaeger or Tempo, with sampling decided deliberately — head sampling is cheap but misses rare errors, tail sampling keeps them but requires buffering and more infrastructure.

A common schema is what makes correlation possible. ECS and OpenTelemetry semantic conventions give event fields consistent names so that an identity event, a host event and a flow record can be joined. Without that, "correlation" means a human guessing which field name means the same thing in three systems.

## Storage and access

Hot, warm and cold tiers trade query latency against cost. Retention is driven by two consumers: compliance obligations and the length of a realistic investigation. A retention window shorter than the time it takes to discover a slow intrusion produces a clean report of nothing.

Log integrity is an architectural property. Append-only stores, signed shipping and tamper-evident structures mean that a compromised application host can write logs but cannot quietly rewrite its own history. The log store itself becomes a high-value target and must be isolated from the systems it observes. Access control on observability data is a security boundary in its own right: logs contain credentials in error messages, personal data and business confidential information, and a broad read permission turns the detection system into an exfiltration target.

## Consumption

Grafana is the shared surface for dashboards; Alertmanager handles routing, silencing and escalation. An alert is a claim that a specific state needs human attention, so it must name the condition, the owner and the action. Alerts without an action are noise that trains operators to ignore the system.

SLOs and error budgets give operations a consumption model that is compatible with security work: a service that burns its error budget is telling the architect something about its design. Alert fatigue is therefore an architectural failure, not an operator weakness. If the pipeline emits events nobody can act on, the emission decision was wrong.

The adversary chapter's detection surfaces are consumers of this pipeline, and the resilience chapter's evidence needs are another. This chapter owns the pipeline; those chapters own what is asked of it.

## What an architect decides at the observability layer

| **Decision** | **The course's answer** |
| --- | --- |
| Emitted events | Named per component before deployment, in a common schema |
| Signal choice | Logs for events, metrics for trends, traces for request paths; no claim that one replaces the others |
| Pipeline | One collection path for operations and security, with shared schema and collector |
| Cardinality and sampling | Bounded labels; sampling strategy chosen for the questions the organisation actually asks |
| Retention | Driven by compliance and realistic investigation windows, tiered by cost |
| Integrity | Append-only, signed shipping, tamper-evidence; log store isolated from observed hosts |
| Access | Least privilege on observability data; treat the store as a sensitive system |
| Alerting | Every alert names a condition, an owner and an action; fatigue treated as a design defect |

**Architectural question a graduate answers:** **what does this system emit, through what pipeline, with what retention and integrity, and who reads it for what purpose?**
