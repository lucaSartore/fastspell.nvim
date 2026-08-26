import { spellCheckDocument } from "cspell-lib";
import type { ValidationIssue } from "cspell-lib";
import type { ConfigureSpellCheckResponse, SpellCheckResponse } from "../types/responses";
import type { CheckSpellRequest, ConfigureSpellCheckerRequest } from "../types/requests";
import type { SpellResponse } from "../types/responses";

var CONFIG_FILE: string | undefined  = undefined;

export function configureSpellCheckRequest(input: ConfigureSpellCheckerRequest): Promise<ConfigureSpellCheckResponse>{
    CONFIG_FILE = input.configFilePath;
    return Promise.resolve({kind: "configure_spell_check_response"})
}

function textToLineNumber(text: string, offset: number): Array<number>{
    const size = text.length;
    var array = Array(size)
    array[0] = offset
    for(var i=1; i<size; i++){
        array[i] = array[i-1]
        if (text[i-1] == '\n'){
            array[i]++
        }
    }
    return array;
}

function convertSpellCheckResult(input: Array<ValidationIssue>, lineOffset: number, originalText: string): SpellCheckResponse{
    const translationTable = textToLineNumber(originalText, lineOffset)
    return {
        kind: "lint",
        problems: input.map(x => {
            return {
                lineStart: translationTable[x.offset],
                lineOfset: Buffer.byteLength(originalText.slice(x.line.offset, x.offset), "utf8"),
                word: x.text
            }
        })
    }
}

export async function processCheckSpellRequest(request: CheckSpellRequest): Promise<SpellResponse> {
	const result = await spellCheckDocument(
		{
			uri: "",
			text: request.text,
			languageId: request.languageId,
			locale: "en",
		},
		{ 
            configFile: CONFIG_FILE,
            noConfigSearch: CONFIG_FILE == undefined
        },
		{},
	);
	return convertSpellCheckResult(result.issues, request.startLine, request.text);
}
