{{- define "k8-application.podSpec" }}
{{- if empty (coalesce .initContainers .containers) }}
{{- fail "failed to tempalte deployment, no containers or initContainers provided" }}
{{- end -}}

imagePullSecrets:
  {{- toYaml .root.Values.imagePullSecrets | nindent 2 }}
terminationGracePeriodSeconds: {{ .root.Values.terminationGracePeriodSeconds }}
serviceAccountName: {{ include "k8-application.serviceAccountName" .root }}
securityContext:
  {{- toYaml .root.Values.podSecurityContext | nindent 2 }}
initContainers:
{{- range $name, $initContainer := .initContainers }}
- name: {{ $name }}
  {{- include "k8-application.container" (dict "root" $.root "c" $initContainer) | nindent 2 }}
{{- end }}
containers:
{{- range $name, $container := .containers }}
- name: {{ $name }}
  {{- include "k8-application.container" (dict "root" $.root "c" $container) | nindent 2 }}
{{- end }}
volumes:
{{- if .root.Values.volumesFreeForm }}
  {{- toYaml .root.Values.volumes | nindent 2 }}
{{- else }}
  {{- range $name, $path := .root.Values.volumes }}
- name: {{ $name }}
  hostPath:
    path: {{ $path }}
    type: Directory
  {{- end }}
{{- end }}
nodeSelector:
  {{- toYaml .root.Values.nodeSelector | nindent 2 }}
affinity:
  {{- toYaml .root.Values.affinity | nindent 2 }}
tolerations:
  {{- toYaml .root.Values.tolerations | nindent 2 }}

{{- end }}

{{- /*
k8-application.container renders core v1 Container spec
required input names, values:
root $
c Container spec
*/}}
{{- define "k8-application.container" }}
{{- if not .c.image }}
{{- fail "failed to template conatiner, no image specified" }}
{{- else if not .c.image.name }}
{{- fail "failed to template conatiner, no image name specified" }}
{{- end -}}

{{- if .c.command }}
command:
  {{- toYaml .c.command | nindent 2 }}
{{- end }}
{{- if .c.args }}
args:
  {{- toYaml .c.args | nindent 2 }}
{{- end }}
{{- if .c.securityContext }}
securityContext:
  {{- toYaml .c.securityContext | nindent 2 }}
{{- end }}
{{- if .c.image.tag }}
image: "{{ .c.image.name }}:{{ .c.image.tag }}"
{{- else if .c.image.digest }}
image: "{{ .c.image.name }}@{{ .c.image.digest }}"
{{- else if .root.Values.imageTag }}
image: "{{ .c.image.name }}:{{ .root.Values.imageTag }}"
{{- else if .root.Values.imageDigest }}
image: "{{ .c.image.name }}@{{ .root.Values.imageDigest }}"
{{- else }}
image: "{{ .c.image.name }}"
{{- end }}
{{- if .c.image.pullPolicy }}
imagePullPolicy: {{ .c.image.pullPolicy }}
{{- end }}
ports:
{{- range .c.ports }}
- containerPort: {{ . }}
  protocol: TCP
{{- end }}
{{- if .c.lifecycle }}
lifecycle:
  {{- toYaml .c.lifecycle | nindent 2 }}
{{- end }}
envFrom:
{{- range $key, $value := .c.environmentValueFromResource }}
  {{- if eq $value.resourceType "configMapRef" }}
- configMapRef:
    name: {{ include "k8-application.fullname" $.root }}-{{ $value.resourceName }}
  {{- end }}
{{- end }}
env:
{{- range $key, $value := .c.environmentValueFrom }}
- name: {{ $key }}
  valueFrom:
  {{- if $value.fieldRef }}
    fieldRef:
      fieldPath: {{ $value.fieldRef }}
  {{- else if $value.resourceFieldRef }}
    resourceFieldRef:
      resource: {{ $value.resourceFieldRef }}
      {{- if $value.containerName }}
      containerName: {{ $value.containerName }}
      {{- end }}
      {{- if $value.divisor }}
      divisor: {{ $value.divisor }}
      {{- end }}
  {{- end }}
{{- end }}
{{- range $key, $value := .c.environment }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- range $key, $value := .c.secretValueFrom }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $value.name }}
      key: {{ $value.key }}
{{- end }}
livenessProbe:
  {{- toYaml .c.livenessProbe | nindent 2 }}
readinessProbe:
  {{- toYaml .c.readinessProbe | nindent 2 }}
startupProbe:
  {{- toYaml .c.startupProbe | nindent 2 }}
resources:
  {{- toYaml .c.resources | nindent 2 }}
volumeMounts:
{{- range $name, $dst := .c.volumes }}
- mountPath: {{ $dst }}
  name: {{ $name }}
{{- end -}}

{{- end -}}
