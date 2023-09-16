import Head from 'next/head';
import { useRouter } from 'next/router'
import { DashboardLayout } from '../components/dashboard-layout';
import { ThreadDetails } from '../components/threads/thread-details';
import { Loading } from '../components/loading';

const Thread = () => {
  const router = useRouter()
  const { query: { id }} = router

  // Don't render the list of emails until we've retrieved the thread_id from the router
  if (!id) {
    return (
      <>
        <Head>
          <title>
            Thread Details 
          </title>
        </Head>
        <Loading />
      </>
    );
  }
  return (
    <>
      <Head>
        <title>
          Thread Details 
        </title>
      </Head>
      <ThreadDetails id={id} />
    </>
  );
}
Thread.getLayout = (page) => (
  <DashboardLayout>
    {page}
  </DashboardLayout>
);

export default Thread;
