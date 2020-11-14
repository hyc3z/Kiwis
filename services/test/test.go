package main

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strconv"
)

type StructWithPtrFields struct {
	Major *int
	Minor *int
}

type ProcessType uint

type ProcessInfo struct {
	PID        uint
	Name       string
	MemoryUsed uint64
	Type       ProcessType
}

type StructInStruct struct {
	name      string
	Fields    StructWithPtrFields
	Processes []ProcessInfo
}

func main() {
	major := 8
	minor := 6
	myStruct := StructInStruct{
		name: "myname is hyc",
		Fields: StructWithPtrFields{
			Major: &major,
			Minor: &minor,
		},
		Processes: []ProcessInfo{
			{
				PID:        4324,
				Name:       "2",
				MemoryUsed: 234,
				Type:       0,
			},
			{
				PID:        238,
				Name:       "2",
				MemoryUsed: 668,
				Type:       0,
			},
		},
	}
	elem := reflect.ValueOf(myStruct)
	fmt.Println(elem)
	relType := elem.Type()
	m := make(map[string]string)
	for i := 0; i < relType.NumField(); i++ {
		if elem.Field(i).Type() == reflect.TypeOf("") {
			m[relType.Field(i).Name] = elem.Field(i).String()
		} else if elem.Field(i).Type() == reflect.TypeOf(StructWithPtrFields{}) {
			versionString := ""
			cudaElem := reflect.ValueOf(StructWithPtrFields{}).Type()
			for t := 0; t < cudaElem.NumField(); t++ {
				if t > 0 {
					versionString += "."
				}
				val := elem.Field(i).Field(t).Elem()
				versionString += strconv.Itoa(int(val.Int()))
			}
			m[relType.Field(i).Name] = versionString
		} else if elem.Field(i).Type() == reflect.TypeOf([]ProcessInfo{}) {
			prefixString := "omaticaya-gpu0-pid"
			arr := elem.Field(i)
			for t := 0; t < arr.Len(); t++ {
				curProc := arr.Index(t)
				procMap := make(map[string]string)
				refType := reflect.TypeOf(ProcessInfo{})
				for s := 0; s < refType.NumField(); s++ {
					typeStr := refType.Field(s).Type
					switch typeStr {
					case reflect.TypeOf(""):
						procMap[refType.Field(s).Name] = curProc.Field(s).String()
					case reflect.TypeOf(uint(0)):
						procMap[refType.Field(s).Name] = strconv.Itoa(int(curProc.Field(s).Uint()))
					case reflect.TypeOf(uint64(0)):
						procMap[refType.Field(s).Name] = strconv.Itoa(int(curProc.Field(s).Uint()))
					case reflect.TypeOf(ProcessType(0)):
						procMap[refType.Field(s).Name] = strconv.Itoa(int(curProc.Field(s).Uint()))
					}
				}
				byteval, _ := json.Marshal(procMap)
				m[prefixString+procMap["PID"]] = string(byteval)
			}

		}
	}
	fmt.Println(m)
}
