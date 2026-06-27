import type { Metadata } from 'next';
import { LegalDocumentPage } from '@/components/legal/LegalDocumentPage';
import { readLegalDocument } from '@/lib/legal-content';

export const metadata: Metadata = {
  title: 'Help & Support | Be Electric',
  description: 'Support information for Be Electric Requestor and Be Electric Tech mobile applications.',
};

export default function SupportPage() {
  return <LegalDocumentPage content={readLegalDocument('support')} />;
}
