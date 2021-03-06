/**
 * LzssP.nc
 * Purpose: Implementation of LZSS-like compression algorithms.
 * Author(s): Matthew Tan Creti
 *
 * Copyright 2011 Matthew Tan Creti
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "bittwiddler.h"

module LzssP {
	provides {
		interface Compressor;
	}
	uses {
		interface BitPacker;
		interface Codebook;
	}
}
implementation {
	command uint8_t Compressor.compress(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint8_t encStartIdx;
		uint8_t encMatchIdx;
		uint8_t dicStartIdx;
		uint8_t dicMatchIdx;
		uint8_t maxOffset;
		uint8_t maxLength;

		call BitPacker.init(out, outMaxLength);

		/* encode all of in[] */
		encStartIdx = 0;
		while(encStartIdx<inLength) {

			maxOffset = 0;
			maxLength = 0;
			/* incrementally search the dictionary until it is no loger possible to find
			   a larger match than maxLength */
			for (dicStartIdx = 0; encStartIdx-dicStartIdx > maxLength; dicStartIdx++) {
				uint8_t matchLength;

				encMatchIdx = encStartIdx;
				dicMatchIdx = dicStartIdx;
				while (encMatchIdx<inLength && dicMatchIdx<encStartIdx && in[encMatchIdx] == in[dicMatchIdx]) {
					encMatchIdx++;
					dicMatchIdx++;
				}

				matchLength = dicMatchIdx - dicStartIdx;
				if (matchLength > maxLength) {
					maxOffset = dicStartIdx;
					/* recorded length is one smaller than actual length */
					maxLength = matchLength - 1;
				}
			}

			if (maxLength < 1) {
				uint16_t code;
				uint8_t codeLength;

				codeLength = call Codebook.getCode(in[encStartIdx], &code);
				if (call BitPacker.pack(0, 1) == FAIL) return 0;
				if (call BitPacker.pack(code, codeLength) == FAIL) return 0;

				encStartIdx++;
			} else {
				uint8_t offsetBits;
				uint8_t lengthBits;
				uint8_t remaining = inLength - encStartIdx;

				if (encStartIdx > 1) {
					int bits = 8 - clz8(encStartIdx - 1);
					offsetBits = bits;
					lengthBits = bits;
				} else {
					offsetBits = 0;
					lengthBits = 0;
				}

				if (remaining < inLength/2) {
					if (remaining > 1) {
						int bits = 8 - clz8(remaining - 1);
						lengthBits = bits;
					} else {
						lengthBits = 0;
					}
				}

				if (call BitPacker.pack(1, 1) == FAIL) return 0;
				if (call BitPacker.pack(maxOffset, offsetBits) == FAIL) return 0;
				if (call BitPacker.pack(maxLength, lengthBits) == FAIL) return 0;

				encStartIdx += maxLength + 1;
			}
		}

		return call BitPacker.getLength();
	}

	command uint8_t Compressor.expand(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode
		return 0;
	}
}
