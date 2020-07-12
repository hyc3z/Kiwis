package main

import (
	"fmt"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
	"os"
	"path/filepath"
)

func CreatePod() {
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
	kubeclient := clientset.CoreV1().Pods("sirius")

	// Create resource object
	object := &corev1.Pod{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Pod",
			APIVersion: "v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      "sirius",
			Namespace: "sirius",
			Labels: map[string]string{
				"app": "sirius",
			},
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				corev1.Container{
					Name:  "sirius-b",
					Image: "hyc3z/sirius-b:cuda-10.1-1.0",
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
					SecurityContext: &corev1.SecurityContext{
						Privileged: ptrbool(false),
					},
				},
				corev1.Container{
					Name:            "sirius-a",
					Image:           "hyc3z/sirius-a:cuda-10.1-resnet-1.0",
					Resources:       corev1.ResourceRequirements{},
					ImagePullPolicy: corev1.PullPolicy("Always"),
					SecurityContext: &corev1.SecurityContext{
						RunAsUser:                ptrint64(1000),
						RunAsNonRoot:             ptrbool(true),
						AllowPrivilegeEscalation: ptrbool(false),
					},
				},
			},
			RestartPolicy:                 corev1.RestartPolicy("Never"),
			TerminationGracePeriodSeconds: ptrint64(30),
			ServiceAccountName:            "sirius-sa",
			ShareProcessNamespace:         ptrbool(true),
		},
	}

	// Manage resource
	_, err = kubeclient.Create(object)
	if err != nil {
		panic(err)
	}
	fmt.Println("Pod Created successfully!")
}

func ptrint64(p int64) *int64 {
	return &p
}

func ptrbool(p bool) *bool {
	return &p
}
