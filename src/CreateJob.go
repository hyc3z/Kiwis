package main

import (
	"fmt"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
	"os"
	"path/filepath"
)

func main() {
	// Create client
	var kubeconfig string
	kubeconfig, ok := os.LookupEnv("KUBECONFIG")
	if !ok {
		kubeconfig = filepath.Join(homedir.HomeDir(), ".kube", "config")
	}

	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		panic(err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	kubeclient := clientset.BatchV1().Jobs("sirius")

	// Create resource object
	object := &batchv1.Job{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Job",
			APIVersion: "batch/v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name: "sirius-job",
		},
		Spec: batchv1.JobSpec{
			BackoffLimit: ptrint32(0),
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Name:      "sirius",
					Namespace: "sirius",
					Labels: map[string]string{
						"app": "sirius",
					},
				},
				Spec: corev1.PodSpec{
					Volumes: []corev1.Volume{
						corev1.Volume{
							Name: "vcuda",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/home/cuda-w-mem-watcher/binaries/10.1/libcuda.so.1",
								},
							},
						},
						corev1.Volume{
							Name: "vcuda-orig",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/home/cuda-w-mem-watcher/binaries/10.1/libcuda.so.1.orig",
								},
							},
						},
						corev1.Volume{
							Name: "vcuda-lib",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/home/cuda-w-mem-watcher/binaries/10.1/libcuda.so.430.64",
								},
							},
						},
						corev1.Volume{
							Name: "vnvml",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/home/cuda-w-mem-watcher/binaries/10.1/libnvidia-ml.so.1",
								},
							},
						},
						corev1.Volume{
							Name: "vnvml-orig",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/home/cuda-w-mem-watcher/binaries/10.1/libnvidia-ml.so.1.orig",
								},
							},
						},
						corev1.Volume{
							Name: "vnvml-lib",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/home/cuda-w-mem-watcher/binaries/10.1/libnvidia-ml.so.430.64",
								},
							},
						},
					},
					Containers: []corev1.Container{
						corev1.Container{
							Name:  "sirius-b",
							Image: "hyc3z/sirius-b:cuda-10.1-1.5",
							Env: []corev1.EnvVar{
								corev1.EnvVar{
									Name: "NODE_NAME",
									ValueFrom: &corev1.EnvVarSource{
										FieldRef: &corev1.ObjectFieldSelector{
											FieldPath: "spec.nodeName",
										},
									},
								},
								corev1.EnvVar{
									Name: "POD_NAME",
									ValueFrom: &corev1.EnvVarSource{
										FieldRef: &corev1.ObjectFieldSelector{
											FieldPath: "metadata.name",
										},
									},
								},
								corev1.EnvVar{
									Name: "POD_NAMESPACE",
									ValueFrom: &corev1.EnvVarSource{
										FieldRef: &corev1.ObjectFieldSelector{
											FieldPath: "metadata.namespace",
										},
									},
								},
								corev1.EnvVar{
									Name:  "NVIDIA_VISIBLE_DEVICES",
									Value: "all",
								},
								corev1.EnvVar{
									Name:  "SCHEDULING_POLICY",
									Value: "default",
								},
								corev1.EnvVar{
									Name:  "MONITOR_GPU_INTERVAL_PATTERN",
									Value: "* * * * * ?",
								},
								corev1.EnvVar{
									Name:  "MONITOR_POLICY_INTERVAL_PATTERN",
									Value: "0 * * * * ?",
								},
								corev1.EnvVar{
									Name:  "MEM_MAX_LIMIT",
									Value: "2147483648",
								},
							},
							Resources: corev1.ResourceRequirements{
								Limits: corev1.ResourceList{
									"memory": *resource.NewQuantity(209715200, resource.BinarySI),
								},
								Requests: corev1.ResourceList{
									"cpu":    *resource.NewQuantity(100, resource.DecimalSI),
									"memory": *resource.NewQuantity(209715200, resource.BinarySI),
								},
							},
							ImagePullPolicy: corev1.PullPolicy("Always"),
							SecurityContext: &corev1.SecurityContext{},
						},
						corev1.Container{
							Name:  "sirius-a",
							Image: "hyc3z/sirius-a:cuda-10.1-resnet-1.0",
							Env: []corev1.EnvVar{
								corev1.EnvVar{
									Name:  "MEM_MAX_LIMIT",
									Value: "2147483648",
								},
							},
							Resources: corev1.ResourceRequirements{},
							VolumeMounts: []corev1.VolumeMount{
								corev1.VolumeMount{
									Name:      "vcuda",
									ReadOnly:  true,
									MountPath: "/usr/lib/x86_64-linux-gnu/libcuda.so.1",
								},
								corev1.VolumeMount{
									Name:      "vcuda-orig",
									ReadOnly:  true,
									MountPath: "/usr/lib/x86_64-linux-gnu/libcuda.so.1.orig",
								},
								corev1.VolumeMount{
									Name:      "vcuda-lib",
									ReadOnly:  true,
									MountPath: "/usr/lib/x86_64-linux-gnu/libcuda.so.430.64",
								},
								corev1.VolumeMount{
									Name:      "vnvml",
									ReadOnly:  true,
									MountPath: "/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1",
								},
								corev1.VolumeMount{
									Name:      "vnvml-orig",
									ReadOnly:  true,
									MountPath: "/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1.orig",
								},
								corev1.VolumeMount{
									Name:      "vnvml-lib",
									ReadOnly:  true,
									MountPath: "/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.430.64",
								},
							},
							ImagePullPolicy: corev1.PullPolicy("Always"),
							SecurityContext: &corev1.SecurityContext{
								RunAsUser:    ptrint64(1000),
								RunAsNonRoot: ptrbool(true),
							},
						},
					},
					RestartPolicy:                 corev1.RestartPolicy("Never"),
					TerminationGracePeriodSeconds: ptrint64(30),
					ServiceAccountName:            "sirius-sa",
					ShareProcessNamespace:         ptrbool(true),
				},
			},
		},
	}

	// Manage resource
	_, err = kubeclient.Create(object)
	if err != nil {
		panic(err)
	}
	fmt.Println("Job Created successfully!")
}

func ptrint64(p int64) *int64 {
	return &p
}

func ptrbool(p bool) *bool {
	return &p
}

func ptrint32(p int32) *int32 {
	return &p
}
