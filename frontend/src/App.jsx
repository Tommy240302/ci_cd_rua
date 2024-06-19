import Navbar from './component/Navbar'
import Home from './page/Home'
import SignIn from './page/SignIn'
import SignUp from './page/SignUp'
import Settings from './page/Settings'
import InfoUser from './component/InfoUser'
import ChangePW from './component/ChangePW'
import ForgotPW from './page/Forgot-PW'
import ResetPW from './page/ResetPW'
import PrivateRoutes from './helper/PrivateRoutes'
import Deck from './page/Deck'
import Decks from './component/Decks.jsx'
import FlipCard from './page/FlipCard'
import Contact from './page/Contact'
import Card from './page/Card'
import Cards from './component/Cards'

import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'




function App() {
  


  return (
    <div>
      <Router>
        <Navbar />
        <Routes>
          {/* private router */}
          <Route element={<PrivateRoutes />}>

          
            <Route path='/decks' element={<Deck />}>
              <Route path='' element={<Decks />} />
              <Route path=':id/learn-cards' element={<FlipCard />} />
            </Route>

            <Route path="/cards" element={<Card />} >
              <Route path='' element={<Cards />} />
            </Route>

            {/* settings */}
            <Route path='/settings' element={<Settings />} >
              <Route path='info' element={<InfoUser />} />
              <Route path='password' element={<ChangePW />} />
            </Route>
          </Route>

          {/* public */}
          <Route path='/' exact element={<Home />} />
          <Route path='/sign-in' element={<SignIn />} />
          <Route path='/sign-up' element={<SignUp />} />
          <Route path='/forgot-password' element={<ForgotPW />} />
          <Route path='/reset-password' element={<ResetPW />} />
          <Route path='/contact' element={<Contact />} />

        </Routes>
      </Router>
    </div>
  );
}

export default App