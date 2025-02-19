'use strict';

import { relaxedHeaders } from './relaxed';
import { simpleHeaders } from './simple';

const generateCanonicalizedHeader = (type, signingHeaderLines, options) => {
    options = options || {};
    let canonicalization = (options.canonicalization || 'simple/simple').toString().split('/').shift().toLowerCase().trim();
    switch (canonicalization) {
        case 'simple':
            return simpleHeaders(type, signingHeaderLines, options);
        case 'relaxed':
            return relaxedHeaders(type, signingHeaderLines, options);
        default:
            throw new Error('Unknown header canonicalization');
    }
};

export { generateCanonicalizedHeader };
