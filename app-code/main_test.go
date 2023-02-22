package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func Test_serveFiles(t *testing.T) {
	req, err := http.NewRequest("GET", "http://localhost/ping", nil)
	if err != nil {
		t.Fatal(err)
	}

	res := httptest.NewRecorder()
	serveFiles(res, req)

	exp := "Pong"
	act := res.Body.String()
	if !strings.Contains(act, exp) {
		t.Fatalf("Expected %s got %s", exp, act)
	}

	req, err = http.NewRequest("GET", "http://localhost", nil)
	if err != nil {
		t.Fatal(err)
	}

	res = httptest.NewRecorder()
	serveFiles(res, req)

	exp = "Current weather in Moscow"
	act = res.Body.String()
	if !strings.Contains(act, exp) {
		t.Fatalf("Expected %s got %s", exp, act)
	}
}

func Test_serveHTTP(t *testing.T) {
	req, err := http.NewRequest("GET", "http://localhost/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	res := httptest.NewRecorder()
	h := home{}
	h.ServeHTTP(res, req)

	mapExp := make(map[string]string)
	mapExp["Status"] = "OK"
	exp, err := json.Marshal(mapExp)
	if err != nil {
		t.Fatalf("Error on converting expected result to stringt. Error: %s" + err.Error())
		return
	}
	act := res.Body.String()
	if string(exp) != act {
		t.Fatalf("Expected %s got %s", exp, act)
	}
}
