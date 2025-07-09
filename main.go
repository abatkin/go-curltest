package main

import (
	"bytes"
	"fmt"
	"os"

	"github.com/alecthomas/kong"
	"github.com/andelf/go-curl"
)

const Version = "1.0.0"

type CLI struct {
	URL          string `arg:"" optional:"" help:"URL to fetch using curl"`
	Version      bool   `help:"Print version information"`
	Verbose      bool   `help:"Enable verbose output"`
	Certificates string `help:"Path to SSL certificates" type:"path"`
}

func main() {
	var cli CLI
	ctx := kong.Parse(&cli)
	if ctx.Error != nil {
		fmt.Printf("Error parsing command line: %v\n", ctx.Error)
		os.Exit(1)
	}

	if cli.Version {
		fmt.Printf("Application version: %s\n", Version)
		fmt.Println(curl.Version())
		os.Exit(0)
	}

	if cli.URL == "" {
		fmt.Println("URL is required")
		os.Exit(1)
	}

	easy := curl.EasyInit()
	defer easy.Cleanup()

	if easy == nil {
		fmt.Println("Error initializing curl")
		os.Exit(1)
	}

	easy.Setopt(curl.OPT_URL, cli.URL)

	cli.setupCertificates(easy)

	if cli.Verbose {
		easy.Setopt(curl.OPT_VERBOSE, 1)
	}

	var buffer bytes.Buffer
	easy.Setopt(curl.OPT_WRITEFUNCTION, func(ptr []byte, userdata interface{}) bool {
		buffer.Write(ptr)
		return true
	})

	if err := easy.Perform(); err != nil {
		fmt.Printf("Error performing request: %v\n", err)
		os.Exit(1)
	}

	httpCode, _ := easy.Getinfo(curl.INFO_RESPONSE_CODE)
	responseCode := httpCode.(int)

	fmt.Printf("Response [%d]:\n%s\n", responseCode, buffer.String())
}

func (cli *CLI) setupCertificates(easy *curl.CURL) {
	certPath := ""
	if cli.Certificates != "" {
		certPath = cli.Certificates
	} else if curlCaBundle := os.Getenv("CURL_CA_BUNDLE"); curlCaBundle != "" {
		certPath = curlCaBundle
	} else if sslCertFile := os.Getenv("SSL_CERT_FILE"); sslCertFile != "" {
		certPath = sslCertFile
	}

	if certPath != "" {
		easy.Setopt(curl.OPT_CAINFO, certPath)
	}
}
