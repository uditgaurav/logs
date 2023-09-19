# Mount Path Setup Guide

## Overview

This guide provides details on setting up environment variables for mounting a disk to a Google Compute Engine (GCE) instance. The table below outlines the required environment variables, their descriptions, and example values.

## Environment Variables Table

<table border="1">
    <thead>
        <tr>
            <th>Environment Variable</th>
            <th>Description</th>
            <th>Example Value</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>VM_USER</code></td>
            <td>Username for the VM you are connecting to.</td>
            <td><code>username</code></td>
        </tr>
        <tr>
            <td><code>INSTANCE_NAME</code></td>
            <td>Name of the Google Compute Engine instance.</td>
            <td><code>my-instance</code></td>
        </tr>
        <tr>
            <td><code>ZONE</code></td>
            <td>The zone where your Google Compute Engine instance is located.</td>
            <td><code>us-central1-a</code></td>
        </tr>
        <tr>
            <td><code>DEVICE_NAME</code></td>
            <td>Identifier for the disk to be mounted.</td>
            <td><code>persistent-disk-1</code></td>
        </tr>
        <tr>
            <td><code>MOUNT_POINT</code></td>
            <td>Directory where the disk will be mounted.</td>
            <td><code>/home/user/mount_point</code></td>
        </tr>
    </tbody>
</table>

## Sample Kubernetes Pod Configuration

Below is a sample Kubernetes Pod YAML configuration that demonstrates how to set up the mount path using K8s pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: hce
spec:
  containers:
    - name: my-container
      image: chaosnative/gcp:0.1.0
      imagePullPolicy: Always
      command: ["/bin/sh", "-c"]
      args: ["sleep 10000"]
      env:
        - name: VM_USER
          value: "uditgaurav"
        - name: INSTANCE_NAME
          value: "gke-cluster-1-default-pool-c742a4dd-3mnf"
        - name: ZONE
          value: "us-central1-c"
        - name: DEVICE_NAME
          value: "persistent-disk-1"
        - name: MOUNT_POINT
          value: "/home/uditgaurav/mydisk"
      volumeMounts:
        - name: cloud-secret-volume
          mountPath: /etc/cloud-secret
  volumes:
    - name: cloud-secret-volume
      secret:
        secretName: cloud-secret

```

## Sample Disk Mount Probe

The following YAML snippet provides a sample probe configuration for mounting the disk path:

```yaml
probe:
    - name: disk-mount
    type: cmdProbe
    mode: EOT
    runProperties:
        probeTimeout: 60s
        retry: 0
        interval: 1s
        stopOnFailure: true
    cmdProbe/inputs:
        command: ./usr/local/bin/run_in_pod.sh
        source:
        image: docker.io/chaosnative/gcp:0.1.0
        inheritInputs: false
        env:
            - name: VM_USER
            value: uditgaurav
            - name: INSTANCE_NAME
            value: gke-cluster-1-default-pool-c742a4dd-3mnf
            - name: ZONE
            value: us-central1-c
            - name: DEVICE_NAME
            value: persistent-disk-1
            - name: MOUNT_POINT
            value: /home/uditgaurav/mydisk
        secrets:
            - name: cloud-secret
            mountPath: /etc/
        comparator:
        type: string
        criteria: contains
        value: Disk mounted successfully
```
