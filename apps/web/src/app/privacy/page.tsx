import type { Metadata } from 'next';
import { LegalDocumentPage } from '@/components/legal/LegalDocumentPage';
import { readLegalDocument } from '@/lib/legal-content';

export const metadata: Metadata = {
  title: 'Privacy Policy | Be Electric',
  description: 'Privacy Policy for Be Electric Requestor and Be Electric Tech mobile applications.',
};

export default function PrivacyPage() {
  return <LegalDocumentPage content={readLegalDocument('privacy_policy')} />;
}
