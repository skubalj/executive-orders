package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/alexflint/go-arg"
	"golang.org/x/sync/errgroup"
)

const rootURL = "https://www.federalregister.gov/api/v1/documents.json" +
	"?per_page=1000" +
	"&fields[]=title" +
	"&fields[]=citation" +
	"&fields[]=document_number" +
	"&fields[]=president" +
	"&fields[]=signing_date" +
	"&fields[]=publication_date" +
	"&order=newest" +
	"&conditions[type][]=PRESDOCU" +
	"&include_pre_1994_docs=true" +
	"&conditions[presidential_document_type][]=executive_order"

type Args struct {
	Output string `arg:"positional,required" help:"Output CSV File"`
}

func (a Args) Description() string {
	return "Download a list of executive orders since 1937 from federalregister.gov"
}

func main() {
	var args Args
	arg.MustParse(&args)

	rowsCh := make(chan []ResponseRow)

	var group errgroup.Group

	// Writer
	group.Go(func() error {
		f, err := os.Create(args.Output)
		if err != nil {
			return err
		}
		defer f.Close()

		w := csv.NewWriter(f)
		defer w.Flush()

		w.Write(ResponseRowHeader)
		for rows := range rowsCh {
			for _, row := range rows {
				err = w.Write(row.ToStrings())
				if err != nil {
					return err
				}
			}
		}

		return nil
	})

	// Fetcher
	group.Go(func() error {
		defer close(rowsCh)
		res, err := makeRequest(rootURL)
		if err != nil {
			return err
		}
		fmt.Printf("Fetched page 1 (%d records)\n", len(res.Results))
		rowsCh <- res.Results

		idx := 1
		for res.NextPageUrl != "" {
			idx++
			res, err = makeRequest(res.NextPageUrl)
			if err != nil {
				return err
			}
			fmt.Printf("Fetched page %d (%d records)\n", idx, len(res.Results))
			rowsCh <- res.Results
		}

		return nil
	})

	if err := group.Wait(); err != nil {
		log.Fatalln(err)
	}
}

type ResponseRow struct {
	Title          string `json:"title"`
	Citation       string `json:"citation"`
	DocumentNumber string `json:"document_number"`
	President      struct {
		Identifier string `json:"identifier"`
		Name       string `json:"name"`
	} `json:"president"`
	SigningDate     string `json:"signing_date"`
	PublicationDate string `json:"publication_date"`
}

var ResponseRowHeader = []string{
	"title",
	"citation",
	"document_number",
	"president",
	"signing_date",
	"publication_date",
}

func (r ResponseRow) ToStrings() []string {
	return []string{
		r.Title,
		r.Citation,
		r.DocumentNumber,
		r.President.Name,
		r.SigningDate,
		r.PublicationDate,
	}
}

type Response struct {
	Count       int           `json:"count"`
	Description string        `json:"description"`
	TotalPages  int           `json:"total_pages"`
	NextPageUrl string        `json:"next_page_url"`
	Results     []ResponseRow `json:"results"`
}

func makeRequest(url string) (Response, error) {
	res, err := http.Get(url)
	if err != nil {
		return Response{}, err
	}

	if res.StatusCode != http.StatusOK {
		return Response{}, fmt.Errorf("got non 200 status code")
	}

	defer res.Body.Close()
	decoder := json.NewDecoder(res.Body)

	var typedRes Response
	err = decoder.Decode(&typedRes)
	if err != nil {
		return Response{}, err
	}

	return typedRes, nil
}
