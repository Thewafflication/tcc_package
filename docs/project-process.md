# TinyCC `_Complex` Project Process

**Document ID:** `TCC-CX-PROC-0001`

**Status:** Adopted for CX1 and CX2

## Purpose

The `_Complex` program applies the pinned Waughtal Software Process to the
TinyCC language change. It uses the same mandatory flow as Waughtal Shell:

```text
Baseline -> Plan -> Specify -> Design -> Implement -> Review -> Verify -> Close
```

## Work Organization

CX0 establishes the process and product baseline. CX1 implements and verifies
the compiler language feature. Later library or release work receives a new
milestone rather than silently expanding CX1.

No production implementation begins until the CX1 plan, requirements,
architecture decision, design, and controlled test specifications are
reviewable. Code completion alone does not close the milestone.

## Roles

| Role | Responsibility | Assignment |
| --- | --- | --- |
| Product owner | Scope and acceptance | Project maintainer |
| Requirements owner | Requirement quality and traceability | Current contributor |
| Architect | Representation and target ABI decisions | Current contributor |
| Implementer | TinyCC source and package automation | Current contributor |
| Verifier | Controlled tests and evidence | Current contributor with reference-compiler oracles |
| Configuration owner | Submodule and tested baselines | Project maintainer/current contributor |
| Process owner | WSP tailoring and closeout | Current contributor |

One contributor may fill several roles. Automated oracle comparisons and
cross-compiler ABI tests provide objective checks where another reviewer is
unavailable. Material findings remain open for maintainer disposition.

## Required Records

- stable `TCC-CX-REQ-NNNN` requirements;
- stable `TC-NNNN` controlled test specifications;
- a milestone plan and design;
- an ADR for the internal representation decision;
- review findings with recorded resolution or deferral;
- CTest-dispatched execution records that preserve failures and reruns; and
- a milestone closeout with exact source/submodule baselines and residual risk.

## Verification and Evidence

CTest is the top-level dispatcher for project-owned automated gates. Upstream
TinyCC suites may retain their native Make dispatch beneath a CTest wrapper.
Each controlled execution records the source revision, TinyCC gitlink, target,
host, configuration, command, timestamps, exit code, status, and captured
output. Only Pass satisfies a required gate.

## Change Control

Changes to the accepted language scope, object representation, target ABI,
supported matrix, library boundary, or test obligations require impact
analysis across requirements, design, source, tests, compatibility, and
release claims. Accepted ADRs are superseded rather than rewritten.

## Closeout

Each milestone closes only when every allocated requirement has passed in every
required configuration, all review findings are resolved or explicitly
accepted, upstream regression gates pass, and unsupported configurations or
library behavior are documented without being represented as complete.
