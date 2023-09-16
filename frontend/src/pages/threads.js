import Head from 'next/head';
import { DashboardLayout } from '../components/dashboard-layout';
import { ThreadListWrapper } from '../components/threads/thread-list-wrapper';

const Threads = () => (
  <>
    <Head>
      <title>
        Threads
      </title>
    </Head>
    <ThreadListWrapper />
  </>
);
Threads.getLayout = (page) => (
  <DashboardLayout>
    {page}
  </DashboardLayout>
);

export default Threads;
