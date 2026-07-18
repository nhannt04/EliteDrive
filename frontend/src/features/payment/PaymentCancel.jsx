import React from 'react';
import { Container, Card, Button } from 'react-bootstrap';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { XCircle, RefreshCw, Home } from 'lucide-react';
import Header from '../../components/layout/Header.jsx';
import PublicFooter from '../../components/layout/PublicFooter.jsx';

const PaymentCancel = () => {
  const [searchParams] = useSearchParams();
  const rentalId = searchParams.get('rentalId');
  const navigate = useNavigate();

  return (
    <div className="bg-surface min-vh-100 d-flex flex-column">
      <Header />
      
      <main className="flex-grow-1 d-flex align-items-center py-5">
        <Container style={{ maxWidth: '600px' }}>
          <Card className="border-0 shadow-lg rounded-4 overflow-hidden text-center p-5">
            <div className="py-4">
              <div className="bg-warning bg-opacity-10 d-inline-flex p-4 rounded-circle mb-4">
                <XCircle size={48} className="text-warning" />
              </div>
              <h2 className="fw-black text-dark mb-2">Giao dịch đã bị huỷ</h2>
              <p className="text-muted body-md mb-4 mx-auto" style={{ maxWidth: '450px' }}>
                Bạn đã huỷ giao dịch thanh toán cho đơn thuê xe số <strong>#{rentalId}</strong>. Đơn đặt xe vẫn được lưu ở trạng thái chờ thanh toán.
              </p>

              <div className="d-flex flex-column gap-2.5">
                <Button 
                  variant="dark" 
                  className="rounded-pill py-2.5 fw-bold d-flex align-items-center justify-content-center gap-2"
                  onClick={() => navigate('/customer/history')}
                >
                  <RefreshCw size={16} /> Xem đơn thuê & Thanh toán lại
                </Button>
                <Button 
                  variant="outline-secondary" 
                  className="rounded-pill py-2.5 fw-bold d-flex align-items-center justify-content-center gap-2"
                  onClick={() => navigate('/')}
                >
                  <Home size={16} /> Quay về Trang chủ
                </Button>
              </div>
            </div>
          </Card>
        </Container>
      </main>

      <PublicFooter />
    </div>
  );
};

export default PaymentCancel;
