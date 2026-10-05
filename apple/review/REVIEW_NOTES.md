# App Review Notes

PowderRunbook is a paid-upfront, offline process-record app for powder-coating shops. It requires no login, account, subscription, ads, analytics, network service or external hardware. The production build intentionally starts with an empty local workspace.

Suggested reviewer flow:
1. Open Powders and add a powder lot with colour/lot/starting weight.
2. Open Jobs, create a job and link that powder lot.
3. Enter target and measured thickness, target and observed cure temperature/time, prep notes and operator-entered QC status.
4. Move the job through Intake → Prep → Mask → Coat → Cure → QC → Done.
5. Open Overview to see the active pipeline, recent completions, recorded powder usage and low-stock count.
6. Open Settings to switch between °C/°F and µm/mil.
7. Open a job and use the iOS share sheet to share its localized text summary.

Differentiation: PowderRunbook is intentionally not a CRM, scheduling, messaging, ordering or team-management service. Its core utility is a private on-device process record tying material lot, cure values, coating thickness and operator QC to each job.

All job and powder data is stored locally on device. PowderRunbook records operator-entered values and never determines or certifies cure/process compliance. Users are directed to manufacturer TDS/SDS and approved shop procedures.
