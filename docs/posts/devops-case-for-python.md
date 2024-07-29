---
date: 2024-07-14
authors: [psb]
categories:
- kubernetes
- python
- devops
---

# The case for programming-languages in the DevOps toolchest

I have long advocated for going beyond [Terraform](https://www.terraform.io/) (TF), [Pulumi](https://www.pulumi.com/docs/) and [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/)/[GCP Deployment Manager](https://cloud.google.com/deployment-manager/docs)/[Azure Resource Manager](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview) and making direct API calls to the cloud-provider services to _edit_ your infrastructure's state. This [post on LinkedIn](https://www.linkedin.com/posts/christopheraddy_i-will-not-worry-about-ai-taking-all-of-our-activity-7216549567914242048-W3Qj?utm_source=share&utm_medium=member_desktop) prompted me to write this blog entry and make my case more publicly rather than just at my work.

The reasons are many but the primary reason I would give you is that whether using TF or any of the other Infrastructure-as-Code (IAC) tools, they all define the final state that you want your infrastructure to be in but not the path to take to get there. Of course, it wouldn't matter if your are creating your infrastructure for the first time. The trouble starts when you need to alter your infrastructure after it has gone into use: none of these IaC tools are without side-effects.

If you find that the state of your infrastructure has drifted away from the "ideal", and you re-run TF to get back to the "ideal", you can never be sure about the path taken to get back to ideal. Are you fixing the network security rules? Why did the network interface have to removed? Which, btw, you did not have the permission to do so anyway so the TF run failed. 
This is where the ability to be explicit about the exact state transitions in your infrastructure is invaluable and hence my case for adding the ability to use explicit API calls to provision your infrastructure.

## I could do that with just the CLI tools

Sure we have [`aws`](https://aws.amazon.com/cli/) for AWS; [`gcloud`](https://cloud.google.com/sdk/docs/) for GCP, [`az`](https://learn.microsoft.com/en-us/cli/azure/) for Azure etc. Yes we could use these CLIs but we would need a series of one-liners in our script and we still need to be able to parse the response from the cloud-provider's API. This is easier to do in a programming language than using bash+jq or in PowerShell. Even if you could do it, bash scripts don't lend themselves to unit tests. You could argue for [Pester](https://pester.dev/) for Powershell but Powershell remains the exception in DevOps environments.

Regardless, there are a few things that can be done more easily using a programming language with a HTTP client library than with CLI alone.

## Exposing a microservice

Many a times, it can be useful to expose a microservice that can work as an orchestrator when building out your infrastructure stack or portions of it; and another upstream service can send a request to the microservice to build it all. The ability to diagnose and detect drift
<!-- For example, I have exposed microservices that, in turn,  builds a Kubernetes cluster and onboards the cluster to Rancher automatically. The upstream process that calls these microservices is driven by an "order form" - fill in the form with the spec for the node pools, number of nodes etc. -->
You can always spawn a shell process from your microservice's backend that runs a script to run the CLI to build the infrastructure component; the capture both stdout and stderr and the return status from the spawned shell... if you think that is a normal thing to do, you aren't a dev.

1. The canonical approach would be to use a library or SDK distributed by the cloud providers themselves and use it to make the API calls.
2. If you choose to use a programming language for which there is no officially supported library from your cloud provider, you might decide find a community-supported library and that would cover most build and maintain-scenarios.
3. If all else fails, you may just choose a popular, well-supported HTTP client library in the language of your choice to make teh API calls but that requires actually going through the API endpoints' documentation with a fine-toothed comb.