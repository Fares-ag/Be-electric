import type { Metadata } from 'next';
import { LegalDocumentPage } from '@/components/legal/LegalDocumentPage';
import { readLegalDocument } from '@/lib/legal-content';

export const metadata: Metadata = {
  title: 'Account Deletion | Be Electric',
  description: 'How to request deletion of your Be Electric CMMS account and associated personal data.',
};

export default function AccountDeletionPage() {
  return <LegalDocumentPage content={readLegalDocument('account_deletion')} />;
}
