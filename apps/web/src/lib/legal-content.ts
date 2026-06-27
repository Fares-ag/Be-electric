import fs from 'fs';
import path from 'path';

const CONTENT_DIR = path.join(process.cwd(), 'src/content/legal');

export type LegalDocumentId =
  | 'privacy_policy'
  | 'terms_of_service'
  | 'support'
  | 'account_deletion';

export function readLegalDocument(id: LegalDocumentId): string {
  return fs.readFileSync(path.join(CONTENT_DIR, `${id}.txt`), 'utf8');
}
