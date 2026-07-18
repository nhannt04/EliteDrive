import React, { useEffect, useState } from 'react';
import { Container, Card, Spinner, Button } from 'react-bootstrap';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { CheckCircle, ArrowRight, AlertTriangle } from 'lucide-react';
import api from '../../infrastructure/api/axios.js';
import Header from '../../components/layout/Header.jsx';
import PublicFooter from '../../components/layout/PublicFooter.jsx';

const PaymentSuccess = () => {
  const [searchParams] = useSearchParams();
  const rentalId = searchParams.get('rentalId');
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [confirmed, setConfirmed] = useState(false);

  useEffect(() => {
    if (!rentalId) {
      setError("Không tìm thấy thông tin mã đơn hàng.");
      setLoading(false);
      return;
    }

    const confirmPaymentStatus = async () => {
      try {
        const response = await api.post(`/v1/payments/confirm/${rentalId}`);
        if (response.data.success) {
          setConfirmed(true);
        } else {
          setError(response.data.message || "Xác thực thanh toán thất bại.");
        }
      } catch (err) {
        console.error("Xác thực thanh toán lỗi:", err);
        setError(err.response?.data?.message || "Đã xảy ra lỗi khi xác minh trạng thái thanh toán từ PayOS.");
      } finally {
        setLoading(false);
      }
    };

    confirmPaymentStatus();
  }, [rentalId]);

  return (
    <div className="bg-surface min-vh-100 d-flex flex-column">
      <Header />
      
      <main className="flex-grow-1 d-flex align-items-center py-5">
        <Container style={{ maxWidth: '600px' }}>
          <Card className="border-0 shadow-lg rounded-4 overflow-hidden text-center p-5">
            {loading ? (
              <div className="py-5">
                <Spinner animation="border" variant="primary" className="mb-4" />
                <h4 className="fw-bold text-dark">Đang xác thực thanh toán...</h4>
                <p className="text-muted small">Vui lòng không tắt hoặc tải lại trang này.</p>
              </div>
            ) : error ? (
              <div className="py-4">
                <div className="bg-danger bg-opacity-10 d-inline-flex p-4 rounded-circle mb-4">
                  <AlertTriangle size={48} className="text-danger" />
                </div>
                <h3 className="fw-bold text-dark mb-3">Thanh toán chưa hoàn tất</h3>
                <p className="text-muted body-md mb-4 mx-auto" style={{ maxWidth: '400px' }}>
                  {error}
                </p>
                <div className="d-flex gap-3 justify-content-center">
                  <Button 
                    variant="outline-secondary" 
                    className="rounded-pill px-4 fw-bold"
                    onClick={() => navigate('/customer/history')}
                  >
                    Lịch sử thuê xe
                  </Button>
                  <Button 
                    variant="primary" 
                    className="rounded-pill px-4 fw-bold"
                    onClick={() => window.location.reload()}
                  >
                    Thử lại
                  </Button>
                </div>
              </div>
            ) : (
              <div className="py-4">
                <div className="bg-success bg-opacity-10 d-inline-flex p-4 rounded-circle mb-4">
                  <CheckCircle size={48} className="text-success" />
                </div>
                <h2 className="fw-black text-dark mb-2">Thanh toán thành công!</h2>
                <p className="text-muted body-md mb-4">
                  Cảm ơn bạn đã lựa chọn dịch vụ của EliteDrive. Đơn đặt xe số <strong>#{rentalId}</strong> của bạn đã được xác nhận thanh toán thành công.
                </p>
                
                <div className="bg-light rounded-3 p-3 mb-4 text-start">
                  <div className="d-flex justify-content-between mb-2">
                    <span className="text-muted">Mã đơn đặt xe:</span>
                    <span className="fw-bold text-dark">#{rentalId}</span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span className="text-muted">Phương thức thanh toán:</span>
                    <span className="fw-bold text-primary">Chuyển khoản QR (PayOS)</span>
                  </div>
                </div>

                <div className="d-flex flex-column gap-2">
                  <Button 
                    variant="dark" 
                    className="rounded-pill py-2.5 fw-bold d-flex align-items-center justify-content-center gap-2"
                    onClick={() => navigate('/customer/history')}
                  >
                    Quản lý chuyến đi của tôi <ArrowRight size={18} />
                  </Button>
                  <Button 
                    variant="link" 
                    className="text-muted text-decoration-none small"
                    onClick={() => navigate('/')}
                  >
                    Quay về Trang chủ
                  </Button>
                </div>
              </div>
            )}
          </Card>
        </Container>
      </main>

      <PublicFooter />
    </div>
  );
};

export default PaymentSuccess;
