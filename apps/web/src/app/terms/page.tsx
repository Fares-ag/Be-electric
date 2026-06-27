import type { Metadata } from 'next';
import { LegalDocumentPage } from '@/components/legal/LegalDocumentPage';
import { readLegalDocument } from '@/lib/legal-content';

export const metadata: Metadata = {
  title: 'Terms of Service | Be Electric',
  description: 'Terms of Service for Be Electric Requestor and Be Electric Tech mobile applications.',
};

export default function TermsPage() {
  return <LegalDocumentPage content={readLegalDocument('terms_of_service')} />;
}
