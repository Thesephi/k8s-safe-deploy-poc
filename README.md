# POC k8s atomic deployment (safety first)

This repo demonstrates how k8s deployment can be safe or unsafe depending on
how the `kubectl apply` command is used

# Prerequisites

To jump into the demo as smoothly as possible, it's recommended that the
following are installed beforehand:
1. k8s itself (e.g. if using Docker Desktop, the built-in Kubernetes is enough)
2. [yq](https://github.com/mikefarah/yq/releases) - a library to parse yaml (.yml) files
3. [ingress-nginx for k8s](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start) (or an equivalence approach to help reach (e.g. `curl`) the k8s service)

# Setup

### 1. Initialize everything

```bash
# run the initial deployment script
./deploy.sh

# expose the service via an ingress;
# @NOTE this step is only needed if
# `ingress-nginx` was used to access
# the k8s service; if you use something
# else, please expose your service in
# accordance to your own setup
kubectl apply -f ingress.yml
```

### 2. Check that everything works
```
curl -s -I localhost/baz
HTTP/1.1 200 OK
```

### 3. Take it further
Assuming we now want to add a label called `version`
to the k8s resources, and we've prepared the
manifest file `deploy-version.yml`, and now all
that's left is to run the deployment script. Let's
see how it works out as we do it the UNSAFE and SAFE
ways.

#### 3.1. Run the UNSAFE deployment script
```
# this basically calls `kubectl apply -f deploy-version.yml` in an unsafe way
./deploy-version-unsafe.sh

namespace/baz-service unchanged
service/baz-service configured
The Deployment "baz-deployment" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app":"baz-service", "version":"2.0"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
```

What happened here was that: k8s reconfigured the `baz-service` (to add the label `version="2.0"`)
but it then failed to reconfigure the `baz-deployment`, due to the `field is immutable` error.
Why k8s behaves this way is beyond the scope of this demo, here we only care about the consequence
of this behavior.

If we curl again, we no longer get the successful 200 OK response:
```
curl -s -I localhost/baz
HTTP/1.1 503 Service Temporarily Unavailable
```

This proves that our previous deployment script was _destructive_ i.e. UNSAFE.

#### 3.2. Reset to the last working state
```bash
# run the initial deployment script again
./deploy.sh

# side-note: we don't need to deploy the `Ingress` resource again as it's not
# part of `deploy-version.yml`, and thus was not "corrupted" by the previous
# unsafe deployment script
```

Ensure everything works again
```
curl -s -I localhost/baz
HTTP/1.1 200 OK
```

#### 3.3. Run the SAFE deployment script

```
./deploy-version-safe.sh

namespace/baz-service configured (dry run)
service/baz-service configured (dry run)
deployment.apps/baz-deployment configured (dry run)
namespace/baz-service unchanged (server dry run)
service/baz-service configured (server dry run)
The Deployment "baz-deployment" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app":"baz-service", "version":"2.0"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
```

As you can see, the deployment still failed. The idea of this demo is not to fix this k8s error,
but to fail safely. This time, the `--dry-run` argument did it job well, and the script "failed early",
so it exited before it had the chance to corrupt the running system.

Let's curl again to make sure things are still running well:
```
curl -s -I localhost/baz
HTTP/1.1 200 OK
```

### 4. Conclusion

This demo reproduced a scenario where applying a collection of k8s manifest (.yml file)
without any special validation mechanism may lead to service disruption (system downtime).

And one "quick win" is to make use of the `--dry-run` argument. It is literally free and effortless
to do so, while the peace of mind it brings is hugely valuable. No service disruption (financial loss)
can ever justify the lack of properly applying an officially supported failsafe mechanism.