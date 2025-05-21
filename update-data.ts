import * as csv from "jsr:@std/csv";
import { Command } from "jsr:@cliffy/command@1.0.0-rc.7";

const ROOT_URL = "https://www.federalregister.gov/api/v1/documents.json" +
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
	"&conditions[presidential_document_type][]=executive_order";

interface Args {
	output: string;
}

interface Response {
	count: number;
	description: string;
	total_pages: number;
	next_page_url: string;
	results: Array<{
		title: string;
		citation: string;
		document_number: string;
		president: {
			identifier: string;
			name: string;
		};
		signing_date: string;
		publication_date: string;
	}>;
}

type RecordRow = {
	title: string;
	citation: string;
	document_number: string;
	president: string;
	signing_date: string;
	publication_date: string;
}

const COLUMNS = [
	"title",
	"citation",
	"document_number",
	"president",
	"signing_date",
	"publication_date",
];

async function main(args: Args) {
	using file = await Deno.create(args.output);
	await ReadableStream.from(reshapePages(getPages()))
		.pipeThrough(new csv.CsvStringifyStream({ columns: COLUMNS }))
		.pipeThrough(new TextEncoderStream())
		.pipeTo(file.writable);

	console.log("Done");
}

async function makeRequest(url: string): Promise<Response> {
	const res = await fetch(url);
	if (res.status !== 200) {
		throw new Error("received non 200 status code");
	}

	return await res.json();
}

async function* getPages() {
	let res = await makeRequest(ROOT_URL);
	console.log(`Fetched page 1 (${res.results.length} records)`);
	yield res;

	let count = 2;
	while (res.next_page_url) {
		res = await makeRequest(res.next_page_url);
		console.log(`Fetched page ${count} (${res.results.length} records)`);
		count++
		yield res;
	}
}

async function* reshapePages(pages: AsyncGenerator<Response>): AsyncGenerator<RecordRow> {
	for await (const page of pages) {
		for (const record of page.results) {
			yield { ...record, president: record.president.name };
		}
	}
}

new Command()
	.name("update-data")
	.description("Download executive order data from the Federal Register's API")
	.arguments("<output:string>")
	.action(async (_, output) => {
		try {
			await main({ output });
		} catch (e) {
			console.error(e);
		}
	})
	.parse();
