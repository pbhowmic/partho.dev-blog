# `kubectl` - list resources 
*It's a trap*

Have you ever tried to, say get a list of all resources in a namespace? Say you would like to  get a list of all `ConfigMaps` in a namespace. 

Suppose I have 2 `ConfigMap`s in a namespace
the first of which is
```yaml
apiVersion: v1
data:
  hello: world
  yoda: do or do not. There is no try
kind: ConfigMap
metadata:
  labels:
    app: blog
  name: hello-world
```
and the second of which is 
```yaml
apiVersion: v1
data:
  palpatine: There is a great disturbance in the force
  vader: I find your lack of faith disturbing
kind: ConfigMap
metadata:
  labels:
    app: blog
  name: sithisms
```
and we `kubectl apply` both of these to a namespace `list-resources-ns` to create them.

Note the `.metadata.labels` in both `ConfigMap`s
```shell
kubectl get configmap --selector app=blog -n list-resources-ns 
```
which gives us the output

```
NAME          DATA   AGE
hello-world   2      25m
sithisms      2      22m
```
but now if we change the command above to 
```shell
kubectl get configmap -n list-resources-ns -oyaml
```
 we get something like this (`.resourceVersion`, `.creationTimestamp` values and the like not withstanding, those would vary in your case)
 ```yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    hello: world
    yoda: do or do not. There is no try
  kind: ConfigMap
  metadata:
    creationTimestamp: "2024-06-30T17:46:35Z"
    labels:
      app: blog
    name: hello-world
    namespace: list-resources-ns
    resourceVersion: "11757"
    uid: 01c03ca8-da39-44ba-991b-7dc4818440cd
- apiVersion: v1
  data:
    palpatine: There is a great disturbance in the force
    vader: I find your lack of faith disturbing
  kind: ConfigMap
  metadata:
    creationTimestamp: "2024-06-30T17:49:39Z"
    labels:
      app: blog
    name: sithisms
    namespace: list-resources-ns
    resourceVersion: "11806"
    uid: 81f99d38-3de8-460f-911f-0d954f165ed1
kind: List
metadata:
  resourceVersion: ""
 ```

So far no surprises. Except for what is going on behind the scenes. 
1. First of all, unsurprisingly, `kubectl` is issuing an HTTP GET to the Kubernetes API server. In fact the GET is issued to the relative URL `/api/v1/namespaces/list-resources-ns/configmaps?labelSelector=app%3Dblog&limit=500` 
2. Secondly, the API server is returning not a YAML but JSON and `kubectl` converts the JSON to a YAML. This shouldn't surprise most devs: YAML is better suited to configuration files but JSON is better suited for transporting data compared to YAML since YAML is pretty finicky about indentation. So, `kubectl` converts the JSON to a YAML before showing you the output.
3. Thirdly, and this might surprise many, you would expect that the API server returns the JSON-equivalent of the above YAML to have been returned.
```json
{
    "apiVersion": "v1",
    "items": [
        {
            "apiVersion": "v1",
            "data": {
                "hello": "world",
                "yoda": "do or do not. There is no try"
            },
            "kind": "ConfigMap",
            "metadata": {
                "creationTimestamp": "2024-06-30T17:46:35Z",
                "labels": {
                    "app": "blog"
                },
                "name": "hello-world",
                "namespace": "list-resources-ns",
                "resourceVersion": "11757",
                "uid": "01c03ca8-da39-44ba-991b-7dc4818440cd"
            }
        },
        {
            "apiVersion": "v1",
            "data": {
                "palpatine": "There is a great disturbance in the force",
                "vader": "I find your lack of faith disturbing"
            },
            "kind": "ConfigMap",
            "metadata": {
                "creationTimestamp": "2024-06-30T17:49:39Z",
                "labels": {
                    "app": "blog"
                },
                "name": "sithisms",
                "namespace": "list-resources-ns",
                "resourceVersion": "11806",
                "uid": "81f99d38-3de8-460f-911f-0d954f165ed1"
            }
        }
    ],
    "kind": "List",
    "metadata": {
        "resourceVersion": ""
    }
}
```
except that what the API server actually returns is 
```json
{
  "kind": "ConfigMapList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "15095"
  },
  "items": [
    {
      "metadata": {
        "name": "hello-world",
        "namespace": "list-resources-ns",
        "uid": "01c03ca8-da39-44ba-991b-7dc4818440cd",
        "resourceVersion": "11757",
        "creationTimestamp": "2024-06-30T17:46:35Z",
        "labels": {
          "app": "blog"
        },
        "managedFields": [
          {
            "manager": "kubectl-create",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2024-06-30T17:46:35Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {
              "f:data": {
                ".": {},
                "f:hello": {},
                "f:yoda": {}
              }
            }
          }
        ]
      },
      "data": {
        "hello": "world",
        "yoda": "do or do not. There is no try"
      }
    },
    {
      "metadata": {
        "name": "sithisms",
        "namespace": "list-resources-ns",
        "uid": "81f99d38-3de8-460f-911f-0d954f165ed1",
        "resourceVersion": "11806",
        "creationTimestamp": "2024-06-30T17:49:39Z",
        "labels": {
          "app": "blog"
        },
        "managedFields": [
          {
            "manager": "kubectl-create",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2024-06-30T17:49:39Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {
              "f:data": {
                ".": {},
                "f:vader": {}
              }
            }
          }
        ]
      },
      "data": {
        "palpatine": "There is a great disturbance in the force",
        "vader": "I find your lack of faith disturbing"
      }
    }
  ]
}
```

Don't believe me? Try issuing the following
```shell
kubectl get cm --selector app=blog -ojson --v=9
```
The differences are many and profound. Here they are in tabular form.

| Differences                      | As reported by `kubectl` | As sent by API server |
|----------------------------------|--------------------------|-----------------------|
| .kind                            | `ConfigMapList`          | `List`                |
| .items[*].kind                   | `ConfigMap`              | *Field absent*        |
| .items[*].metadata.managedFields | *Field absent*           | *Field present*       |

Now, why does this matter? It may not matter most of the times except when you are a dev creating a client-side tool, either using one of the officially supported [kubernetes client libraries](https://github.com/kubernetes-client) or maybe just use [`curl`](https://curl.se/) or any number of HTTP libraries; and you are looking to parse the JSON returned by the API server, you could easily be flummoxed
