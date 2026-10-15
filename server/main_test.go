package main

import (
	"encoding/json"
	"testing"
)

func TestMerge(t *testing.T) {
	var stored, incoming []Script
	json.Unmarshal([]byte(`[{"id":"a","modified":1,"text":"old"},{"id":"b","modified":5,"text":"keep"}]`), &stored)
	json.Unmarshal([]byte(`[{"id":"a","modified":2,"text":"new"},{"id":"b","modified":4,"text":"stale"},{"id":"c","modified":1,"deleted":true}]`), &incoming)
	out, _ := json.Marshal(merge(stored, incoming))
	want := `[{"id":"a","modified":2,"text":"new"},{"id":"b","modified":5,"text":"keep"},{"id":"c","modified":1,"deleted":true}]`
	if string(out) != want {
		t.Fatalf("got %s", out)
	}
}
