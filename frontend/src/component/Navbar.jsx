import { Link, useLocation, useNavigate } from 'react-router-dom'
import useAuth from '../context/AuthContext'


function Navbar() {

  const {auth, signOut} = useAuth()
  const location = useLocation()
  const navigate = useNavigate()

  function handleSignOut() {
    signOut()
    navigate('/')
  }

  function handleShowMenu() {
    document.getElementById('menu-mobile').style.display = 'flex'
  }
  
  function handleCloseMenu() {
    document.getElementById('menu-mobile').style.display = 'none'
  }



  if (location.pathname !== '/sign-in' && location.pathname !== '/sign-up' && !location.pathname.includes('settings')) {
    return <nav className='bg-[#F0F6F6] h-16 px-4 md:px-24 flex justify-between items-center fixed left-0 right-0 top-0 z-10'>
      <div className=''>
        <Link to={'/'} className='text-blue-700 text-xl md:text-3xl font-bold'>
          Flashcard
        </Link>
      </div>
      {/*  */}
      <ul className='hidden md:flex gap-x-4 lg:gap-x-8 text-sm uppercase'>
        <li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname === '/' ? 'link-active' : ''} to={'/'} >Trang chủ</Link>
        </li>
        {auth &&<li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname.includes('/decks') ? 'link-active' : ''} to={'/decks'} >Bộ thẻ</Link>
        </li>}
        {auth &&<li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname.includes('/cards') ? 'link-active' : ''} to={'/cards'} >Thẻ</Link>
        </li>}
       
        <li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname === '/contact' ? 'link-active' : ''} to={'/contact'} >Liên hệ</Link>
        </li>
      </ul>
      {/* ẩn hiện tùy theo authenticate*/}
      {!auth && (
        <div className='mr-14 md:mr-0 flex gap-x-3'>
          <Link to='sign-in' className='bg-transparent hover:bg-blue-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded'>
            Đăng nhập
          </Link>
          <Link to='sign-up' className='bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow'>
            Đăng ký
          </Link>
        </div>
      )}
      {auth && (
        <div className='mr-14 md:mr-0 flex gap-x-2 items-center'>
          <div className='dropdown'>
            <div className='h-2'></div>
            <div className='dropdown-btn h-9 w-9 rounded-full overflow-hidden cursor-pointer'>
              <img src={auth.avatar} loading="lazy" className='w-full h-full' alt='' />
            </div>
            <div className='h-2'></div>
            <div className='dropdown-content-left'>
              <Link to={'/settings/info'} className=''>Cài đặt</Link>
              <a onClick={handleSignOut}>Đăng xuất</a>
            </div>
          </div>
          <img src='/down-arrow.png' className='w-4 h-4'></img>
        </div>
      )}

      {/* menu mobile */}
      <div className='fixed right-4 flex md:hidden'>
        <button onClick={handleShowMenu}>
          <img className='w-8' src='/menu.png' alt='' />
        </button>
        <ul id='menu-mobile' className='hidden fixed top-0 bottom-0 right-0 uppercase text-sm w-64 bg-blue-500 text-white font-medium p-8 flex-col gap-y-4'>
          <button onClick={handleCloseMenu}>
            <img src='/close.png' className='w-8' alt='' />
          </button>
          <li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname === '/' ? 'link-active-mobile' : ''} to={'/'} >Trang chủ</Link>
        </li>
        {auth &&<li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname.includes('/decks') ? 'link-active-mobile' : ''} to={'/decks'} >Bộ thẻ</Link>
        </li>}
        {auth &&<li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname.includes('/cards') ? 'link-active-mobile' : ''} to={'/cards'} >Thẻ</Link>
        </li>}
      

  
        <li className='hover:cursor-pointer font-medium'>
          <Link className={location.pathname === '/contact' ? 'link-active-mobile' : ''} to={'/contact'} >Liên hệ</Link>
        </li>
        </ul>
      </div>
    </nav>
  }
  else {
    return null
  }
}

export default Navbar