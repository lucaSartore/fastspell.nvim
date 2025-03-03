import type { SpellRequest } from "./types/requests.ts";
import type { SpellResponse } from "./types/responses.ts";
import {createInterface} from "node:readline";

import processCheckSpellRequest from "./requests/spell_check_request";

const rl = createInterface({
	input: process.stdin,
	output: process.stdout,
});


async function processRequest(request: SpellRequest): Promise<SpellResponse> {
	switch (request.Kind) {
		case "check_spell":
			return await processCheckSpellRequest(request);
		default:
			return {
				kind: "error",
				message: `Unknown request kind: ${request.Kind}`,
			};
	}
}

rl.on("line", async (input: string) => {
	var request: SpellRequest = JSON.parse(input);
	var response = await processRequest(request);
	console.log(JSON.stringify(response));
});
