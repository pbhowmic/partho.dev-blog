---
date: 2024-07-06
authors: [psb]
categories:
- kubernetes
- Datadog
---

# Kubernetes init containers - the Datadog example

*EDIT - July 11 2024 - Adding explicit links to external docs*

When I look at the [examples](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#examples) of init containers and how they are used, I am left dissatisfied because the examples feel contrived. So I decided to furnish a real example. This is how Datadog (DD) does it which you can read [here](https://docs.datadoghq.com/tracing/trace_collection/library_injection_local/?tab=kubernetes). Hold off on reading this documentation if you are yet unfamiliar with Kubernetes operators. It will only confuse you.

## The init container's job

The DD instrumentation library is injected into an application container by way of an init container.
For example, suppose you have containerized Java application. Before your application container is run, the DD init container is run, which adds the required Java library - as a jar file - to the filesystem and terminates. Then the actual application container runs and it starts using the jar file.

### Why not add the jar file during container build?

You may be asking yourselves why this could not have been done at application container build-time? The simple reason: you may not be in a position to recontainerize the application. It may well be a 3rd-party application container which needs to be instrumented.

## The Admission Controller's role *(optional)*

To continue with the Java application example, the gist is that when the DD agent runs in the cluster, it also runs a DD Admission Controller (DDAC) which registers itself with the Kubernetes control plane which intercepts Pod creation requests to the Kubernetes API server before persistence of the Pod objects. This is where the Pod's spec is modified to insert an init container *if it contains some annotations that the DD Admission Controller is looking for*. Pods without those modifications will be left alone.
The annotations tell the DDAC which Pods need to be modified to have the init container inserted in the spec and furthermore, what version of the jar file will be injected.

While I have used Java applications as an example, the same technique is applicable for application containers where the application may have be written in .Net/Python/Golang etc.

## Links

1. The Datadog Admission Controller - [https://docs.datadoghq.com/containers/cluster_agent/admission_controller/?tab=datadogoperator](https://docs.datadoghq.com/containers/cluster_agent/admission_controller/?tab=datadogoperator)
2. Datadog automatic instrumentation with local library injection - [https://docs.datadoghq.com/tracing/trace_collection/library_injection_local/?tab=kubernetes](https://docs.datadoghq.com/tracing/trace_collection/library_injection_local/?tab=kubernetes)
3. Datadog tutorial: Instrumenting a Java application  [https://docs.datadoghq.com/tracing/guide/tutorial-enable-java-admission-controller/#instrument-your-app-with-datadog-admission-controller](https://docs.datadoghq.com/tracing/guide/tutorial-enable-java-admission-controller/#instrument-your-app-with-datadog-admission-controller)