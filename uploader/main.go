package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"

	_ "github.com/joho/godotenv/autoload"
)

var ErrUnknown = fmt.Errorf("unknown error")

const PinFileToIpfsUrl = "https://api.pinata.cloud/pinning/pinFileToIPFS"
const PinJsonToIpfsUrl = "https://api.pinata.cloud/pinning/pinJSONToIPFS"

type PinResponse struct {
	IpfsHash    string `json:"IpfsHash"`
	PinSize     int    `json:"PinSize"`
	Timestamp   string `json:"Timestamp"`
	IsDuplicate bool   `json:"IsDuplicate"`
}

type Metadata struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Image       string `json:"image"`
}

type IpfsService struct {
	apiKey string
	secret string
	client *http.Client
}

func (svc *IpfsService) PinFileToIpfs(ctx context.Context, file io.Reader, filename string) (*PinResponse, error) {
	body := &bytes.Buffer{}

	m := multipart.NewWriter(body)

	part, err := m.CreateFormFile("file", filename)
	if err != nil {
		return nil, err
	}

	if _, err := io.Copy(part, file); err != nil {
		return nil, err
	}

	m.Close()

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, PinFileToIpfsUrl, body)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", m.FormDataContentType())
	req.Header.Set("pinata_api_key", svc.apiKey)
	req.Header.Set("pinata_secret_api_key", svc.secret)

	resp, err := svc.client.Do(req)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, errorFromResponse(resp)
	}

	var pinResp PinResponse

	if err := json.NewDecoder(resp.Body).Decode(&pinResp); err != nil {
		return nil, err
	}

	return &pinResp, nil
}

func (svc *IpfsService) PinJsonToIpfs(ctx context.Context, data interface{}) (*PinResponse, error) {
	body := &bytes.Buffer{}

	if err := json.NewEncoder(body).Encode(data); err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, PinJsonToIpfsUrl, body)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("pinata_api_key", svc.apiKey)
	req.Header.Set("pinata_secret_api_key", svc.secret)

	resp, err := svc.client.Do(req)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, errorFromResponse(resp)
	}

	var pinResp PinResponse

	if err := json.NewDecoder(resp.Body).Decode(&pinResp); err != nil {
		return nil, err
	}

	return &pinResp, nil
}

func errorFromResponse(resp *http.Response) error {
	var data map[string]interface{}

	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return err
	}

	if msg, ok := data["error"].(string); ok {
		return fmt.Errorf("pinata error: %s", msg)
	}

	if m, ok := data["error"].(map[string]interface{}); ok {
		if msg, ok := m["details"].(string); ok {
			return fmt.Errorf("pinata error: %s", msg)
		}
	}

	return ErrUnknown
}

func main() {
	// walk dir and find files
	entry, err := os.ReadDir("./assets")
	if err != nil {
		log.Fatal(err)
	}

	apiKey := os.Getenv("PINATA_API_KEY")
	secret := os.Getenv("PINATA_SECRET_KEY")

	svc := &IpfsService{
		apiKey: apiKey,
		secret: secret,
		client: http.DefaultClient,
	}

	log.Println("Uploading files to IPFS...")

	for _, e := range entry {
		if e.IsDir() {
			continue
		}

		file, err := os.Open(fmt.Sprintf("./assets/%s", e.Name()))
		if err != nil {
			log.Fatal(err)
		}
		defer file.Close()

		resp, err := svc.PinFileToIpfs(context.Background(), file, e.Name())
		if err != nil {
			log.Fatal(err)
		}

		imageURI := fmt.Sprintf("ipfs://%s", resp.IpfsHash)

		metadata := &Metadata{
			Name:        e.Name(),
			Description: "Thank you for your support!",
			Image:       imageURI,
		}

		resp, err = svc.PinJsonToIpfs(context.Background(), metadata)
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Uploaded %s to IPFS: %s\n", e.Name(), resp.IpfsHash)
	}

}
