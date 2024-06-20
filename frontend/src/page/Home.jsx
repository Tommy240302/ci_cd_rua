
import useAuth from '../context/AuthContext'


function Home() {

  const {test} = useAuth()

  return (
    <div className="mt-[60px] w-full">
       <img className="w-full h-full" loading='lazy' src="/study.jpg" alt=""/>
       {test}
       build ci/cd thành công + Quang
    </div>
  )
}

export default Home
