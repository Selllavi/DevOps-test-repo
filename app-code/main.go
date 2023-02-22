package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

// client for http
var client = &http.Client{Timeout: 10 * time.Second}

// lon of Moscow city
var lon = 37.6174943

// lat of Moscow city
var lat = 55.7504461

// apiKey Api key for authentication in weather broadcast api third-party service
var apiKey = os.Getenv("API_KEY")

// Broadcast
// Structure for parsing data collected with broadcast api third-party service
type Broadcast struct {
	Main       Main   `json:"main"`
	Visibility int    `json:"visibility"`
	Wind       Wind   `json:"wind"`
	Clouds     Clouds `json:"clouds"`
	Sys        Sys    `json:"sys"`
}

type Main struct {
	Temp      float64 `json:"temp"`
	FeelsLike float64 `json:"feels_like"`
	TempMin   float64 `json:"temp_min"`
	TempMax   float64 `json:"temp_max"`
	Pressure  float64 `json:"pressure"`
	Humidity  float64 `json:"humidity"`
	SeaLevel  float64 `json:"sea_level"`
	GrndLevel float64 `json:"grnd_level"`
}

type Wind struct {
	Speed float64 `json:"speed"`
	Def   float64 `json:"deg"`
	Gust  float64 `json:"gust"`
}

type Clouds struct {
	All float64 `json:"all"`
}

type Sys struct {
	Sunrise float64 `json:"sunrise"`
	Sunset  float64 `json:"sunset"`
}

type home struct{}

// Serve HTTP response with data formatted in Html
func serveFiles(rw http.ResponseWriter, r *http.Request) {
	rw.Header().Add("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
	if r.URL.Path == "/styles.css" {
		http.ServeFile(rw, r, "./static/styles.css")
	} else if r.URL.Path == "/ping" {
		http.ServeFile(rw, r, "./static/pong.html")
	} else {
		tmplt := template.New("weather.html")
		tmplt, _ = tmplt.ParseFiles("./static/weather.html")

		resp, err := client.Get(fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=%s", lat, lon, apiKey))
		if err != nil {
			fmt.Printf("No response from weather broadcast site. Error: %s\n\n", err.Error())
		}
		defer func(Body io.ReadCloser) {
			err := Body.Close()
			if err != nil {
				fmt.Printf("Error on connection closure. Error: %s\n", err.Error())
			}
		}(resp.Body)

		broadcast := Broadcast{}
		err = json.NewDecoder(resp.Body).Decode(&broadcast)
		if err != nil {
			fmt.Printf("Error on json decoding. Error: %s\n", err.Error())
			return
		}
		err = tmplt.Execute(rw, broadcast)
		if err != nil {
			fmt.Printf("Error on templating creation. Error: %s\n", err.Error())
			return
		}
	}
}

// Serve HTTP response with OK formatted in Json
func (h home) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
	rw.Header().Add("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
	rw.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["Status"] = "OK"
	rw.WriteHeader(200)
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		log.Fatalf("Error happened in JSON marshal. Err: %s", err)
	}
	_, err = rw.Write(jsonResp)
	if err != nil {
		return
	}
	return
}

// Main Server functionality
// Covered with TLS for security reason
func main() {
	if apiKey == "" {
		log.Fatal("Sorry, server could not be started. Please, mandatory system environment API_KEY is not specified.")
	}
	mux := http.NewServeMux()
	mux.Handle("/health", home{})
	mux.HandleFunc("/", serveFiles)
	server := http.Server{Addr: ":8080", Handler: mux}
	log.Print("Server started successfully on 8080.")
	log.Fatal(server.ListenAndServe())
}
