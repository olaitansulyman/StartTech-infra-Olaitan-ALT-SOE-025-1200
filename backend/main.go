package main

import (
    "fmt"
    "net/http"
)

func health(w http.ResponseWriter, r *http.Request){
    w.Header().Set("Content-Type","application/json")
    w.WriteHeader(200)
    fmt.Fprintln(w, `{"status":"healthy"}`)
}

func main(){
    http.HandleFunc("/health", health)
    http.ListenAndServe(":8080", nil)
}
