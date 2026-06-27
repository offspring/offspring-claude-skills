# Argo Workflows Skill — Design Spec

## Overview

A general-purpose Claude Code skill for writing, maintaining, and understanding Argo Workflow YAML schemas. Covers Workflows, WorkflowTemplates, and ClusterWorkflowTemplates. No CronWorkflow support.

## Goals

- Generate correct Argo Workflow YAML from natural-language requirements
- Help debug, extend, and fix existing workflow definitions
- Explain workflow structure and behavior section by section
- Catch common mistakes before they hit the cluster

## File Structure

```
skills/argo-workflows/
├── SKILL.md
├── reference/
│   ├── resource-kinds.md
│   ├── template-types.md
│   ├── parameters-artifacts.md
│   ├── patterns.md
│   └── pitfalls.md
```

### SKILL.md

Orchestrator file. Contains:

- Frontmatter: `name: argo-workflows`, `description`, `allowed-tools`
- Mode detection logic (write / maintain / understand)
- Instructions for which reference files to read per mode
- Validation step definition (always runs pitfalls checklist as final step)

Does NOT contain Argo reference content — delegates to companion files.

### reference/resource-kinds.md

Spec reference for the three supported resource kinds, all under `apiVersion: argoproj.io/v1alpha1`:

**Workflow** — single execution instance. Required fields: `entrypoint`, `templates`. Key optional fields: `arguments`, `volumes`, `volumeClaimTemplates`, `serviceAccountName`, `parallelism`, `activeDeadlineSeconds`, `retryStrategy`, `onExit`, `hooks`, `ttlStrategy`, `templateDefaults`, `nodeSelector`, `tolerations`, `affinity`, `imagePullSecrets`, `suspend`, `synchronization`, `metrics`.

**WorkflowTemplate** (v2.4+, full spec v2.7+) — namespace-scoped reusable workflow definition. Same `spec` structure as Workflow. Referenced via `templateRef` (specific template) or `workflowTemplateRef` (entire workflow).

**ClusterWorkflowTemplate** (v2.8+) — cluster-scoped reusable definition. Same as WorkflowTemplate but accessible from any namespace. Referenced with `templateRef` + `clusterScope: true` or `workflowTemplateRef` + `clusterScope: true`.

Includes canonical YAML skeleton for each kind.

### reference/template-types.md

All template types with when-to-use guidance and minimal examples.

**Definition templates** (do work):

| Type | Purpose |
|------|---------|
| Container | Schedule a Kubernetes container; stdout exported as `result` |
| Script | Container wrapper with inline `source:` field |
| Resource | kubectl-style operations (create, apply, delete, patch) |
| Suspend | Pause for duration or until manual resume |
| HTTP | Execute HTTP requests (v3.2+) |
| Container Set | Multiple containers in a single pod |

**Invocator templates** (orchestrate):

| Type | Purpose |
|------|---------|
| Steps | List-of-lists; outer sequential, inner parallel; supports `when:` |
| DAG | Tasks with `dependencies` arrays; no-dep tasks start immediately |

Each type gets: required fields, optional fields, a minimal working example, and a one-line "when to pick this" note.

### reference/parameters-artifacts.md

**Parameter passing patterns:**

| Scope | Declaration | Reference syntax |
|-------|-------------|-----------------|
| Global | `spec.arguments.parameters` | `{{workflow.parameters.name}}` |
| Template input | `inputs.parameters` | `{{inputs.parameters.name}}` |
| Between steps | Step outputs | `{{steps.stepName.outputs.parameters.name}}` or `{{steps.stepName.outputs.result}}` |
| Between DAG tasks | Task outputs | `{{tasks.taskName.outputs.parameters.name}}` |

**Artifacts:**

- Declared under `inputs.artifacts` and `outputs.artifacts` with a `path` field
- Default archive: tar+gzip; disable with `archive: none: {}`
- Storage backends: S3, GCS, HTTP, Git, HDFS, Artifactory, Azure, OSS
- Garbage collection: `OnWorkflowCompletion` or `OnWorkflowDeletion`

**Expression syntax:**

- Double-quote all parameter references in YAML: `"{{inputs.parameters.x}}"`
- Expression evaluation with `expr:` for conditional logic
- `when:` clauses in steps for conditional execution

### reference/pitfalls.md

Validation checklist run after writing or modifying any workflow YAML:

1. Template parameter references are double-quoted (`"{{inputs.parameters.x}}"`)
2. `templateRef` uses `clusterScope: true` when referencing ClusterWorkflowTemplates
3. All `inputs.parameters` referenced in the template body are declared
4. DAG task dependencies reference valid task names defined in the same DAG
5. Steps/DAG tasks referencing outputs use correct syntax (`steps.X.outputs` vs `tasks.X.outputs`)
6. `entrypoint` references an existing template name in the same spec
7. Artifact paths don't have trailing `/` for S3 unarchived directories
8. `retryStrategy.retryPolicy` is explicitly set (default changed to `Always` in v3.5+)
9. Resource templates have valid `action` values (create, apply, delete, patch)
10. Volume mounts reference volumes declared in `spec.volumes` or `volumeClaimTemplates`
11. `onExit` handler template name exists in the templates list
12. Lifecycle hooks don't depend on outputs from the step they're attached to (not available yet)
13. DAG `failFast` behavior is intentional (defaults to `true` — one failure stops new tasks)
14. Secrets referenced by ClusterWorkflowTemplates exist in the *executing* namespace, not the template's cluster scope
15. `volumeClaimTemplates` PVCs are destroyed on workflow completion — don't use for persistent data
16. Memoization ConfigMaps have the required label `workflows.argoproj.io/configmap-type: Cache`
17. Memoization cache values stay under ConfigMap 1MB limit
18. Synchronization mutex/semaphore names don't conflict across unrelated workflows
19. Sidecar containers have readiness checks — startup order is not guaranteed

Each item includes: what to check, why it matters, and what the fix looks like.

### reference/patterns.md

Reusable patterns organized by resource kind, plus cross-cutting concerns.

**Secrets:**

Secrets use standard Kubernetes mechanisms. Work identically across Workflow, WorkflowTemplate, and ClusterWorkflowTemplate specs.

- **Env var from secret:** `env[].valueFrom.secretKeyRef` with `name` (secret name) and `key` (secret key)
- **Volume-mounted secret:** Declare a `secret` volume in `spec.volumes`, mount via `volumeMounts` in the template container
- **Gotcha:** The secret must exist in the namespace where the Workflow *runs*, not where the ClusterWorkflowTemplate is defined — cluster-scoped templates run in the submitting namespace

Includes minimal YAML examples for both approaches.

**ClusterWorkflowTemplate patterns:**

- **Shared library:** Define common tasks (notifications, deployments, linting) as ClusterWorkflowTemplates, reference from any namespace via `templateRef` + `clusterScope: true`
- **Full workflow from template:** Use `workflowTemplateRef` + `clusterScope: true` to create a Workflow entirely from a ClusterWorkflowTemplate, overriding parameters via `spec.arguments`
- **Composition:** Mix inline templates with `templateRef` calls to ClusterWorkflowTemplates in DAG/steps — build workflows from local + shared pieces
- **Parameter override:** Workflow-level `arguments.parameters` merge with and override template defaults

**WorkflowTemplate patterns:**

- **Namespace-scoped reuse:** Same patterns as ClusterWorkflowTemplate but without `clusterScope` — use when templates only need to be shared within a single namespace
- **Converting Workflow to template:** Change `kind: Workflow` to `kind: WorkflowTemplate` — same spec structure
- **workflowMetadata** (v2.10.2+): Auto-apply labels/annotations to Workflows generated from the template
- **Version compatibility:** v2.4-v2.6 only support `templates` and `arguments` — no `entrypoint`. Full `WorkflowSpec` from v2.7+

**Workflow patterns:**

- **DAG diamond:** A -> {B, C} -> D via `dependencies` arrays
- **Fan-out/fan-in:** `withItems` for static lists, `withParam` for dynamic JSON arrays from prior step outputs
- **Exit handlers:** `onExit` template runs regardless of outcome; `{{workflow.status}}` yields Succeeded/Failed/Error; supports `when` clauses
- **Retry with backoff:** `retryStrategy` with `limit`, `retryPolicy`, `backoff` (duration/factor/maxDuration), and `expression` for conditional retries
- **templateDefaults** (v3.1+): Workflow-wide defaults inherited by all templates; template-level values override via strategic merge patch
- **Sidecars:** Additional containers in the same pod; container startup order is random — poll-wait for readiness
- **Conditional execution:** `when:` clauses in steps for skipping steps based on prior outputs or parameters

**Volume patterns:**

- **volumeClaimTemplates:** Dynamic PVCs auto-created/destroyed with the workflow — for scratch space between steps
- **Existing PVC:** `persistentVolumeClaim.claimName` for data that must persist beyond the workflow
- **emptyDir:** Shared temp storage within a single pod (container set or sidecar patterns)
- **Template-level volumes:** Scoped to individual templates for dynamic PVC scenarios

**Synchronization:**

- **Mutex:** `synchronization.mutex.name` — single concurrent execution of a workflow or template
- **Semaphore:** `synchronization.semaphore.configMapKeyRef` — N concurrent executions, count stored in a ConfigMap
- Can be applied at workflow-level or template-level; template-level limits apply across all workflows
- **Gotcha:** Multi-lock workflows block all other workflows needing any subset of those locks

**Memoization:**

- `memoize` field with `key` (template expression), `maxAge`, and `cache.configMap.name`
- ConfigMap must have label `workflows.argoproj.io/configmap-type: Cache`
- Requires RBAC: `create` and `update` on `configmaps`
- **Gotcha:** ConfigMaps have a 1MB limit — large outputs will fail silently

## Modes

### Write Mode

Triggered when the user asks to create/generate a new workflow.

1. Ask what the workflow should do (if not already clear)
2. Read `reference/resource-kinds.md` to pick the right resource kind
3. Read `reference/template-types.md` to select template types
4. Read `reference/parameters-artifacts.md` if parameter passing or artifacts are involved
5. Read `reference/patterns.md` for applicable patterns (secrets, volumes, synchronization, composition, etc.)
6. Generate the YAML
7. Read `reference/pitfalls.md` and run the validation checklist against the output
8. Present the result with any warnings

### Maintain Mode

Triggered when the user points to existing YAML and asks to fix, extend, or debug it.

1. Read the existing YAML
2. Identify the resource kind and template types in use
3. Read relevant reference files based on what's in the YAML (including `reference/patterns.md` for secrets, volumes, synchronization, etc.)
4. Diagnose the issue or implement the requested change
5. Read `reference/pitfalls.md` and run the validation checklist
6. Present the change with explanation

### Understand Mode

Triggered when the user provides YAML and asks for an explanation.

1. Read the YAML
2. Read relevant reference files to ground the explanation
3. Walk through the YAML section by section:
   - Resource kind and metadata
   - Entrypoint and overall flow
   - Each template: type, inputs, outputs, what it does
   - Parameter/artifact wiring between templates
   - Retry strategies, exit handlers, hooks if present
4. Flag any pitfalls found during the walkthrough

## Allowed Tools

```yaml
allowed-tools:
  - Read
  - Bash(cat *)
```

The skill only reads files and YAML content. No writes — the user decides what to do with the output.

## Out of Scope

- CronWorkflows
- Argo Events integration
- Argo CD integration
- Cluster administration (RBAC, controller configuration)
- Workflow submission or execution (no `argo submit` commands)
